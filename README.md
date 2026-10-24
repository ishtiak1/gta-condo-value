# GTA Condo Value

A single-page tool that estimates the market value of a resale condo apartment in the Greater Toronto Area.

## What it does

- Starts from an area $/sq ft benchmark for 25 neighbourhoods across Toronto, Peel, York Region, Halton and Durham.
- Adjusts for size, bedrooms, bathrooms, den, floor, view, outdoor space, condition, building age, amenities, transit access and maintenance fees.
- Adds parking and locker values separately.
- Blends in your own recent comparable sales (time-adjusted, with parking removed) and narrows the range as you add more.
- Shows each adjustment in dollars, plus an estimate of Ontario and Toronto land transfer tax.

## Run it

No build step. Open `index.html` in a browser, or serve the folder:

```sh
python3 -m http.server 8000
```

To host it free, enable GitHub Pages for this repo (Settings → Pages → deploy from the `main` branch, root folder).

## Data and limits

Area benchmarks are approximate 2025–26 resale averages for the unit alone, excluding parking. They are not a live feed. Update the `AREAS` table in `index.html`, or type over the benchmark in the page, using the latest [TRREB Market Watch](https://trreb.ca/market-data/market-watch/) figures.

This is a planning estimate, not an appraisal. Confirm values with a REALTOR® CMA or a licensed appraiser.
