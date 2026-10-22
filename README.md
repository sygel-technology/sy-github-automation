# Sygel GitHub Automation

Automatizaciones centralizadas de GitHub para la organización [`sygel-technology`](https://github.com/sygel-technology).

**Sync forks**: detecta los forks de la organización y sincroniza su rama predeterminada con la del repositorio original **sin `--force`**.

## Estructura

```text
sy-github-automation/
├── .github/workflows/sync-forks.yml  # Programación y ejecución manual
├── config/excluded-forks.txt         # Exclusiones opcionales
├── scripts/sync-forks.sh             # Consulta y sincronización
├── .editorconfig
├── .gitignore
└── README.md
```

## Qué hace

1. Consulta a GitHub todos los repositorios que sean forks de `sygel-technology` (incluidos los privados visibles para el token).
2. Omite los archivados y los que figuren en `config/excluded-forks.txt`.
3. Ejecuta `gh repo sync OWNER/REPO` para cada fork restante.
4. Publica el resultado de cada fork en el **Summary** de GitHub Actions.
5. Si un fork no se puede sincronizar, continúa con los demás y deja la ejecución marcada como fallida.

La sincronización utiliza el comportamiento predeterminado de `gh repo sync`: **fast-forward**, sin sobrescribir cambios divergentes. No utiliza `--force`, no modifica otras ramas ni actualiza etiquetas (*tags*).

## ¿Qué ocurre si falla un fork?

Puede deberse a:

- La rama predeterminada del fork ha divergido del upstream.
- Hay una regla de protección o un *ruleset* que impide la actualización.
- El repositorio original ya no es accesible o su rama predeterminada no coincide.

El workflow **no fuerza ni descarta commits**. Registra el error, sigue con los demás y marca el job como fallido para que se revise.

Para gestionar un fork personalizado, la opción recomendada es integrar el upstream en una rama de trabajo y abrir un PR. Esa funcionalidad **no está implementada** en este repositorio inicial.

## Ejecución local (opcional)

Requiere `gh` instalado y autenticado:

```bash
export GH_TOKEN="$(gh auth token)"
GITHUB_ORG=sygel-technology DRY_RUN=true bash scripts/sync-forks.sh
```

Para ejecutar realmente, utilizar `DRY_RUN=false` con un token que tenga permisos de escritura. El secreto nunca debe almacenarse en el repositorio.
