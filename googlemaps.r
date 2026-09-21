# ------------------------------------------------------------
# Lib and wd
# ------------------------------------------------------------

library(sf)
setwd("/Users/osx/Documents/Github/InteractiveGPXmap/")

# ------------------------------------------------------------
# Settings
# ------------------------------------------------------------

gpx_file = "Stelvio to Dolomites.gpx"
gpx_file = file.path("gpx_files",gpx_file)

# Number of waypoints per Google Maps section
points_per_section = 8

# Output file containing macOS Terminal commands
output_file = gsub(".gpx|.GPX",".txt",gpx_file)
output_file = gsub("gpx_files","googlemap_links",output_file)
print(output_file)

# ------------------------------------------------------------
# Read GPX
# ------------------------------------------------------------

st_layers(gpx_file)
gpx = st_read(gpx_file, layer = "route_points", quiet = TRUE)

# Make sure coordinates are WGS84
gpx = st_transform(gpx, 4326)

# ------------------------------------------------------------
# Extract coordinates
# ------------------------------------------------------------

coords = st_coordinates(gpx)

# Google Maps wants:
# latitude,longitude
#
# sf gives:
# X = longitude
# Y = latitude

points = data.frame(
  latitude = coords[, "Y"],
  longitude = coords[, "X"]
)

# Remove Z/M columns if present and keep original order
points$id = seq_len(nrow(points))


# ------------------------------------------------------------
# Split waypoints into sections
# ------------------------------------------------------------

sections <- split(
  points,
  ceiling(points$id / (points_per_section - 1))
)

# ------------------------------------------------------------
# Add last location of each section to next section
# ------------------------------------------------------------

for (i in seq_len(length(sections) - 1)) {
  sections[[i + 1]] <- rbind(
    sections[[i]][nrow(sections[[i]]), ],
    sections[[i + 1]]
  )
}

# ------------------------------------------------------------
# Create Google Maps URLs
# ------------------------------------------------------------

make_google_maps_url = function(section) {

  # First point = origin
  origin = paste0(
    section$latitude[1],
    ",",
    section$longitude[1]
  )

  # Last point = destination
  destination = paste0(
    section$latitude[nrow(section)],
    ",",
    section$longitude[nrow(section)]
  )

  # Everything between origin and destination = waypoints
  if (nrow(section) > 2) {

    waypoints = paste0(
      section$latitude[2:(nrow(section) - 1)],
      ",",
      section$longitude[2:(nrow(section) - 1)],
      collapse = "|"
    )

    # URL encode the | characters
    waypoints = URLencode(waypoints, reserved = TRUE)

    url = paste0(
      "https://www.google.com/maps/dir/?api=1",
      "&origin=", origin,
      "&destination=", destination,
      "&waypoints=", waypoints
    )

  } else {

    url = paste0(
      "https://www.google.com/maps/dir/?api=1",
      "&origin=", origin,
      "&destination=", destination
    )

  }

  return(url)
}


urls = lapply(sections, make_google_maps_url)

# ------------------------------------------------------------
# Write urls to txt file
# ------------------------------------------------------------

urls = unlist(urls)
writeLines(urls,output_file)
