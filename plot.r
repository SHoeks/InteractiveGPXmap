# pkg
library(jsonlite)
library(sf)
library(mapview)
library(leaflet)
library(htmlwidgets)
library(shiny)
library(base64enc)
library(magick)

# wd
setwd("/Users/osx/Documents/Github/InteractiveGPXmap/")

# dir with gpx track
dir = "gpx_files"

# gpx files
files = list.files(dir,pattern=".gpx|.GPX",full.names=TRUE)

# select file
print(files)
files = files[1]

# read gpx
st_layers(files)
track = st_read(files,layer = "tracks")
track_p = st_read(files,layer = "track_points")
track$index = 1

# starting points
track_p_st = track_p[1,]

# simplified tracks for low zoom
track_simple = st_simplify(track, dTolerance = 100)
track_simple$index = 1

# mapview
if(FALSE){
  mapview(track,col.region="red",color="red") + 
    mapview(track_p_st,col.region="orange")
}

# function for rendering leaflet
onRenderJS = "
function(el, x) {

    var map = this;

    var simple = map.getPane('simple');
    var detailed = map.getPane('detailed');

    function updateLayers() {

        console.log('zoom', map.getZoom());

        if (map.getZoom() >= 12) {
            simple.style.display = 'none';
            detailed.style.display = 'block';
        } else {
            simple.style.display = 'block';
            detailed.style.display = 'none';
        }

    }

    updateLayers();
    map.on('zoomend', updateLayers);

}
"

# leaflet responsive zoom detail rendering
m = leaflet() |>
  addTiles() |>
  addProviderTiles(providers$OpenStreetMap, group = "OpenStreetMap") |>
  addProviderTiles(providers$CartoDB.Positron, group = "Positron") |>
  addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") |>
  addLayersControl(
    baseGroups = c("OpenStreetMap", "Positron", "Satellite"),
    options = layersControlOptions(collapsed = FALSE)
  ) |>
  addMapPane("simple", zIndex = 410) |>
  addMapPane("detailed", zIndex = 411) |>
  addMarkers(data = track_p_st, label = ~files) |>
  addPolylines(data = track_simple, options = pathOptions(pane = "simple", layerId = ~index)) |>
  addPolylines(data = track, options = pathOptions(pane = "detailed", layerId = ~index)) |>
  onRender(onRenderJS)

# save html map 
outfile = gsub(".gpx|.GPX",".html",files)
outfile = gsub(dir,"html_export",outfile)
print(outfile)
saveWidget(m, file = outfile, selfcontained = TRUE)
