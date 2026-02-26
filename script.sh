set -euo pipefail

########################
# НАСТРОЙКИ
########################
TO_EMAIL="damian.sargers@gmail.com"

ACCESS_LOG="/var/log/nginx/access.log"
ERROR_LOG="/var/log/nginx/error.log"

TOP_N=20

STATE_DIR="/var/lib/hourly_web_report"
LOCK_FILE="/var/lock/hourly_web_report.lock"

SCRIPT_LOG="/var/log/hourly_web_report.log"

########################
# ВСПОМОГАТЕЛЬНЫЕ
########################
log() {
  local ts
  ts="$(date '+%F %T')"
  echo "[$ts] $*" | tee -a "$SCRIPT_LOG" >&2
}

need_bin() {
  command -v "$1" >/dev/null 2>&1
}

mkdir -p "$STATE_DIR"

ACCESS_STATE="$STATE_DIR/access.state"
ERROR_STATE="$STATE_DIR/error.state"
LASTRUN_STATE="$STATE_DIR/lastrun.state"


read_new_lines() {
  local file="$1"
  local state="$2"

  [[ -f "$file" ]] || return 0

  local cur_inode cur_size
  cur_inode="$(stat -c '%i' "$file" 2>/dev/null || echo 0)"
  cur_size="$(stat -c '%s' "$file" 2>/dev/null || echo 0)"

  local prev_inode=0 prev_off=0
  if [[ -f "$state" ]]; then
    read -r prev_inode prev_off < "$state" || true
  fi

  if [[ "$cur_inode" != "$prev_inode" ]] || [[ "$cur_size" -lt "$prev_off" ]]; then
    prev_off=0
  fi

  local start=$((prev_off + 1))
  if [[ "$start" -le "$cur_size" ]]; then
    tail --bytes=+"$start" "$file"
  fi

  echo "$cur_inode $cur_size" > "$state"
}


patch_postfix_transport_if_needed() {
  if ! need_bin postconf; then
    return 0
  fi

  local dt rt
  dt="$(postconf -h default_transport 2>/dev/null || true)"
  rt="$(postconf -h relay_transport 2>/dev/null || true)"

  if [[ "${dt:-}" == "error" || "${rt:-}" == "error" ]]; then
    log "Postfix настроен на transport=error (письма будут отбиваться). Патчу на smtp..."
    postconf -e "default_transport=smtp" >>"$SCRIPT_LOG" 2>&1 || true
    postconf -e "relay_transport=smtp" >>"$SCRIPT_LOG" 2>&1 || true
    systemctl reload postfix >>"$SCRIPT_LOG" 2>&1 || true
    log "Postfix пропатчен: default_transport=smtp, relay_transport=smtp"
  fi
}

send_report() {
  local subject="$1"
  local body_file="$2"

  if need_bin msmtp; then
    log "Найден msmtp — отправляю через него."
    {
      echo "To: $TO_EMAIL"
      echo "Subject: $subject"
      echo "MIME-Version: 1.0"
      echo "Content-Type: text/plain; charset=UTF-8"
      echo
      cat "$body_file"
    } | msmtp -a default "$TO_EMAIL"
    return 0
  fi

  if need_bin sendmail; then
    patch_postfix_transport_if_needed

    log "Найден sendmail — отправляю."
    {
      echo "To: $TO_EMAIL"
      echo "Subject: $subject"
      echo "MIME-Version: 1.0"
      echo "Content-Type: text/plain; charset=UTF-8"
      echo
      cat "$body_file"
    } | sendmail -t
    return 0
  fi

  if need_bin mail; then
    log "Найден mail — отправляю."
    mail -s "$subject" "$TO_EMAIL" < "$body_file"
    return 0
  fi

  if need_bin mailx; then
    log "Найден mailx — отправляю."
    mailx -s "$subject" "$TO_EMAIL" < "$body_file"
    return 0
  fi

  if [[ "$(id -u)" -eq 0 ]]; then
    if need_bin apt-get; then
      log "Не найдено sendmail/mail/mailx/msmtp. Пытаюсь поставить postfix+mailutils (apt-get)..."
      export DEBIAN_FRONTEND=noninteractive

      echo "postfix postfix/mailname string $(hostname -f 2>/dev/null || hostname)" | debconf-set-selections || true
      echo "postfix postfix/main_mailer_type select Local only" | debconf-set-selections || true

      apt-get update -y >>"$SCRIPT_LOG" 2>&1 || true
      apt-get install -y postfix mailutils >>"$SCRIPT_LOG" 2>&1 || true
      systemctl enable --now postfix >>"$SCRIPT_LOG" 2>&1 || true

      if need_bin sendmail; then
        patch_postfix_transport_if_needed
        log "Postfix установлен, sendmail появился — отправляю письмо."
        {
          echo "To: $TO_EMAIL"
          echo "Subject: $subject"
          echo "MIME-Version: 1.0"
          echo "Content-Type: text/plain; charset=UTF-8"
          echo
          cat "$body_file"
        } | sendmail -t
        return 0
      fi

    elif need_bin yum; then
      log "Не найдено sendmail/mail/mailx/msmtp. Пытаюсь поставить postfix+mailx (yum)..."
      yum install -y postfix mailx >>"$SCRIPT_LOG" 2>&1 || true
      systemctl enable --now postfix >>"$SCRIPT_LOG" 2>&1 || true

      if need_bin sendmail; then
        patch_postfix_transport_if_needed
        log "Postfix установлен, sendmail появился — отправляю письмо."
        {
          echo "To: $TO_EMAIL"
          echo "Subject: $subject"
          echo "MIME-Version: 1.0"
          echo "Content-Type: text/plain; charset=UTF-8"
          echo
          cat "$body_file"
        } | sendmail -t
        return 0
      fi
    fi
  fi

  log "ОШИБКА: нечем отправить письмо. Нужен msmtp или postfix/sendmail/mail. Отчёт лежит тут: $body_file"
  return 1
}

########################
# БЛОКИРОВКА ОТ ПАРАЛЛЕЛИ
########################
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
  log "Скрипт уже запущен (lock: $LOCK_FILE). Выходим."
  exit 0
fi

########################
# ВРЕМЕННОЙ ДИАПАЗОН
########################
NOW_EPOCH="$(date +%s)"
NOW_HUMAN="$(date '+%F %T %z')"

LAST_EPOCH="$NOW_EPOCH"
if [[ -f "$LASTRUN_STATE" ]]; then
  read -r LAST_EPOCH < "$LASTRUN_STATE" || LAST_EPOCH="$NOW_EPOCH"
fi

FROM_HUMAN="$(date -d "@$LAST_EPOCH" '+%F %T %z' 2>/dev/null || date '+%F %T %z')"
TO_HUMAN="$NOW_HUMAN"

########################
# ЧИТАЕМ ТОЛЬКО НОВОЕ
########################
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

NEW_ACCESS="$TMP_DIR/new_access.log"
NEW_ERROR="$TMP_DIR/new_error.log"

read_new_lines "$ACCESS_LOG" "$ACCESS_STATE" > "$NEW_ACCESS" || true
read_new_lines "$ERROR_LOG"  "$ERROR_STATE"  > "$NEW_ERROR"  || true

ACCESS_LINES="$(wc -l < "$NEW_ACCESS" 2>/dev/null || echo 0)"
ERROR_LINES="$(wc -l < "$NEW_ERROR" 2>/dev/null || echo 0)"

log "Новых строк (с прошлого запуска): access=$ACCESS_LINES, error=$ERROR_LINES. Диапазон: $FROM_HUMAN -> $TO_HUMAN"

#######################
# СТРОИМ ОТЧЁТ
########################
REPORT="$TMP_DIR/report.txt"

{
  echo "Почасовой отчёт по веб-логам"
  echo "Период обработки: $FROM_HUMAN  ->  $TO_HUMAN"
  echo "Хост: $(hostname -f 2>/dev/null || hostname)"
  echo
  echo "Источники логов:"
  echo "  access: $ACCESS_LOG"
  echo "  error : $ERROR_LOG"
  echo
  echo "============================================================"
  echo "ТОП-$TOP_N IP-адресов по числу запросов (с прошлого запуска)"
  echo "------------------------------------------------------------"

  if [[ -s "$NEW_ACCESS" ]]; then
    awk '{print $1}' "$NEW_ACCESS" | sort | uniq -c | sort -nr | head -n "$TOP_N"
  else
    echo "Нет новых строк в access-логе."
  fi

  echo
  echo "============================================================"
  echo "ТОП-$TOP_N URL по числу запросов (с прошлого запуска)"
  echo "------------------------------------------------------------"

  if [[ -s "$NEW_ACCESS" ]]; then

    awk '{print \$7}' "$NEW_ACCESS" | sort | uniq -c | sort -nr | head -n "$TOP_N"
  else
    echo "Нет новых строк в access-логе."
  fi

  echo
  echo "============================================================"
  echo "HTTP-коды ответов и их количество (с прошлого запуска)"
  echo "------------------------------------------------------------"

  if [[ -s "$NEW_ACCESS" ]]; then
    awk '{print \$9}' "$NEW_ACCESS" \
      | grep -E '^[0-9]{3}$' \
      | sort | uniq -c | sort -nr
  else
    echo "Нет новых строк в access-логе."
  fi

  echo
  echo "============================================================"
  echo "Ошибки веб-сервера/приложения (с прошлого запуска)"
  echo "------------------------------------------------------------"

  if [[ -s "$NEW_ERROR" ]]; then
    grep -E -i '(\[error\]|\[crit\]|\[alert\]|\[emerg\]|exception|traceback|fatal|panic)' "$NEW_ERROR" \
      | tail -n 200 || true
  else
    echo "Нет новых строк в error-логе."
  fi

  echo
  echo "============================================================"
  echo "Примечания"
  echo "------------------------------------------------------------"
  echo "- Подсчёты делаются по новым строкам логов с момента прошлого запуска (по смещению в байтах)."
} > "$REPORT"

########################
# ОТПРАВЛЯЕМ
########################
SUBJECT="Отчёт nginx: $(hostname) [$FROM_HUMAN -> $TO_HUMAN]"

if send_report "$SUBJECT" "$REPORT"; then
  log "Письмо поставлено на отправку: $TO_EMAIL"
else
  SAVED="$STATE_DIR/последний_отчёт_$(date '+%Y%m%d_%H%M%S').txt"
  cp -f "$REPORT" "$SAVED" || true
  log "Письмо отправить не удалось. Отчёт сохранён локально: $SAVED"
fi

echo "$NOW_EPOCH" > "$LASTRUN_STATE"

log "Готово."
exit 0