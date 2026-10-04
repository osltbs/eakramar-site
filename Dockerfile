# Образ сайта-визитки: nginx со встроенной статикой.
# Статика копируется В образ, а не монтируется — образ самодостаточен,
# деплой это docker pull + up. Под будущий CI/CD: пайплайн собирает
# готовый артефакт.

FROM nginx:1.27-alpine

# конфиг виртуального хоста
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# статика сайта: index.html, css/, js/, резюме
COPY site/ /usr/share/nginx/html/

# порт 80 внутри; наружу и TLS — на уровне compose и хоста
EXPOSE 80

# базовый образ уже запускает nginx в foreground, CMD наследуется
