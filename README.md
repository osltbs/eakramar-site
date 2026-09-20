# eakramar.ru — сайт-визитка

Статический сайт в контейнере: nginx с TLS, готовый к деплою на VPS.
Собственный образ со встроенной статикой — под будущий CI/CD-пайплайн.

Простой снаружи, за ним — контейнеризация, TLS, безопасный деплой на боевой
домен без простоя.

---

## Стек

- **nginx 1.27-alpine** — отдаёт статику, держит TLS
- **Docker Compose** — сборка образа и запуск
- **Let's Encrypt** на боевом домене (webroot), самоподписанный на стенде

Статика (`index.html`, CSS, JS, резюме) копируется **в образ** — он
самодостаточен. Деплой сводится к `docker pull` + `up`.

---

## Структура

```
.
├── compose.yaml
├── Dockerfile
├── nginx/default.conf          конфиг виртуального хоста
├── site/                       статика, копируется в образ
│   ├── index.html
│   ├── css/main.css
│   ├── js/main.js
│   └── rezume-kramar.pdf
├── scripts/gen-cert.sh         самоподписанный сертификат для стенда
├── certs/                      сертификаты — НЕ в Git
├── certbot-webroot/            ACME-challenge — НЕ в Git
└── .gitignore
```

---

## Обкатка на стенде

Проверяется вся схема с самоподписанным сертификатом, до боевого домена.

```bash
./scripts/gen-cert.sh eakramar.ru
docker compose up -d --build
docker compose ps
```

Проверка:

```bash
# редирект HTTP → HTTPS
curl -sI http://localhost | head -3

# статика по HTTPS (-k игнорирует самоподписанный)
curl -skI https://localhost | head -3
curl -sk https://localhost/ | grep -o '<title>.*</title>'

# ресурсы отдаются
curl -skI https://localhost/css/main.css | head -1
curl -skI https://localhost/js/main.js | head -1
curl -skI https://localhost/rezume-kramar.pdf | head -1
```

Через браузер (с записью в hosts рабочей машины) — `https://localhost`
или `https://<адрес-стенда>`, браузер предупредит о самоподписанном.

---

## Деплой на VPS (путь А)

Сертификаты Let's Encrypt остаются на хосте, контейнер их читает. Метод
обновления меняется с плагина nginx на webroot — плагин не работает через
границу контейнера.

**Порядок важен: сначала сменить метод сертификата на живом хостовом nginx,
убедиться через `--dry-run`, и только потом контейнеризовать.**

### 1. Перевести certbot на webroot (nginx ещё хостовый)

```bash
# каталог для challenge, общий с будущим контейнером
sudo mkdir -p /var/www/certbot

# в конфиг хостового nginx добавить location для challenge:
#   location /.well-known/acme-challenge/ { root /var/www/certbot; }
sudo nginx -t && sudo systemctl reload nginx

# сменить метод в renewal-конфиге
sudo certbot certonly --webroot -w /var/www/certbot \
  -d eakramar.ru -d www.eakramar.ru --dry-run
```

`--dry-run` проверяет, не трогая сертификат. Прошло — метод рабочий.

### 2. Подготовить проект на VPS

```bash
git clone <репозиторий> && cd eakramar-site

# в compose.yaml переключить монтирование сертификатов на боевые:
#   - /etc/letsencrypt/live/eakramar.ru:/etc/nginx/certs:ro
#   - /var/www/certbot:/var/www/certbot:ro

# в nginx/default.conf раскомментировать HSTS

docker compose build
```

### 3. Переключение (окно недоступности — секунды)

```bash
sudo systemctl stop nginx        # погасить хостовый
docker compose up -d             # поднять контейнерный
curl -sI https://eakramar.ru | head -1
```

Проверить, что сайт открывается. Если что-то не так — мгновенный откат:

```bash
docker compose down
sudo systemctl start nginx
```

### 4. Отключить хостовый nginx насовсем

Только после того, как контейнер проверен:

```bash
sudo systemctl disable nginx
```

Автообновление сертификата (таймер certbot дважды в день) продолжает работать
на хосте, кладёт challenge в общий каталог, контейнерный nginx его отдаёт.
После обновления nginx перечитывает сертификат — добавить в хук certbot:
`docker compose exec web nginx -s reload`.

---

## Известные особенности

**Метод сертификата сменён с nginx на webroot.** Плагин nginx управляет
процессом nginx напрямую и через границу контейнера не работает. Webroot
общается с nginx через общий каталог — работает в любой схеме.

**HSTS только на боевом домене.** На стенде с самоподписанным сертификатом
закомментирован: иначе браузер запомнил бы домен как HTTPS-only и мешал бы
при смене сертификата.

**Резюме — заглушка.** Файл `site/rezume-kramar.pdf` в репозитории пустой,
настоящее резюме кладётся при деплое.

---

## Что дальше

- **certbot в контейнере** (путь Б) — весь TLS внутри compose, без хостового
  certbot. Отдельный контейнер certbot с общими томами для сертификатов
  и challenge.
- **CI/CD** — пайплайн собирает образ, сканирует trivy, пушит в реестр,
  выкатывает на VPS. Этот проект специально сделан с образом в сборке под него.
