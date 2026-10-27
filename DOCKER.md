# Run Akashic with Docker

Docker Compose provides a scraper container and a Vite development server.
Scraped records, caches, and generated app data stay in the working tree; they
are not baked into the development images.

## Requirements

- Docker Engine with the Compose plugin
- Network access for scraping vendor sites and downloading dependencies

The Linux scraper image includes `poppler-utils` and Tesseract OCR. Apple's
Vision OCR is macOS-only and is not available in this container.

## Refresh the library and run locally

From the repository root:

```sh
docker compose build scraper app
docker compose run --rm scraper bash scripts/refresh-pages.sh
docker compose up app
```

Open <http://localhost:5173>. The refresh script scrapes all registered
sources, reuses cached build documents, writes the JSON bundle into
`app/static/data/`, and stores the SQLite database and caches in `data/`.
Source logs are saved under `data/cache/refresh-pages/`. It retries failures
and exits nonzero if any source still fails after three attempts.

The app service runs `npm ci` and starts Vite on container startup. Stop it
with Ctrl-C. For later data updates, rerun the scraper command; the app sees
the changed bundle through the bind mount.
The scraper is a tools-profile service, so plain `docker compose up` starts
only the app; invoke the scraper with `docker compose run` as shown above.

To scrape only one source instead, for example:

```sh
docker compose run --rm scraper pcblib scrape pedalpcb --refresh-pages
docker compose run --rm scraper pcblib export
```

Use `--refresh` instead of `--refresh-pages` if the vendor's build documents
should also be downloaded again.

## Static container preview

After generating the data bundle, build and serve the prerendered static site:

```sh
docker compose --profile static up --build static
```

Open <http://localhost:8080>. This image serves `app/build/` with Nginx and
does not change or replace the existing Cloudflare deployment.

The static build copies the exported JSON into the image. Refresh and export
the data before rebuilding the static image to include updated records.
