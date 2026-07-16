# pi-nix

Nix-пакет [pi coding agent](https://pi.dev) (`@earendil-works/pi-coding-agent`) из готового npm-тарбола + личный pi-пакет с аддонами.

## Как устроено

- `package.nix` — `buildNpmPackage` поверх npm-тарбола (dist/ уже собран апстримом, сборки из исходников нет).
- `npm-shrinkwrap.json` — вендорный лок из тарбола с дозаписанными `integrity` для сиблинг-пакетов pi (апстрим публикует их без integrity, `fetchNpmDeps` такое не ест).
- `sources.json` + `update.sh` + cron-воркфлоу — авто-апдейт ежедневно в 9:00 МСК с проверкой сборки.
- `pi-package/` — личный pi-пакет: кастомные расширения в `extensions/`, скилы в `skills/`.

## Аддоны

Кастомные — класть в `pi-package/extensions` (`.ts`/`.js`) и `pi-package/skills`, подключается один раз локальным путём (pi грузит без копирования, правки видны сразу):

```bash
pi install ~/home/pi-nix/pi-package
```

Сторонние — pi управляет ими сам: `pi install npm:<pkg>`, обновление `pi update --all`.
