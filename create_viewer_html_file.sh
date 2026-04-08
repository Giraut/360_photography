#!/bin/sh
# Call this script with the filename of the equirectangular 360 degree image for which to create an HTML file to view and its title

URLROOT=https://giraut.github.io/360_photography/

# Check that we have the required arguments
if [ "$1" = "" ] || [ "$2" = "" ] || [ "$3" = "" ] || [ "$4" = "" ]; then
  echo "Usage: $0 <equirectangular file> <title> <starting yaw angle> <starting pitch angle> [hotspots file]"
  exit
fi

EQIMG=$1
TITLE=$2
YAW=$3
PITCH=$4
HOTSPOTS_FILE=$5

# If a hotspots file has been specified, load it
# If it's empty (for example by passing /dev/null) then turn on hotspot debugging
HOTSPOTS='        "hotSpotDebug": false'
if [ "${HOTSPOTS_FILE}" != "" ]; then
  HOTSPOTS=$(awk '{print "        " $0}' ${HOTSPOTS_FILE})
  if [ "${HOTSPOTS}" = "" ]; then
    HOTSPOTS='        "hotSpotDebug": true'
  fi
fi

# Determine the root name of the equirectangular file
EQIMG_BASENAME=$(basename $EQIMG)
EQIMG_ROOTNAME=$(echo ${EQIMG_BASENAME} | sed -e "s/\.[0-9a-zA-Z]*$//")
THUMBNAIL=images/thumbnails/${EQIMG_ROOTNAME}-thumbnail.jpg

# Create the thumbnail
convert $1 -gravity center -crop 25%x50%+0+0 -scale x800 360_logo.png -compose over -composite ${THUMBNAIL}

# Create the HTML file
cat <<EOF > ${EQIMG_ROOTNAME}.html
<!DOCTYPE HTML>
<html>

  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${TITLE}</title>
    <meta property="og:title" content="${TITLE}" />
    <meta property="og:description" content="${TITLE} - 360-degree photo sphere" />
    <meta property="og:image" content="${URLROOT}/${THUMBNAIL}" />
    <meta property="og:image:type" content="images/jpeg" />
    <meta property="og:image:width" content="800" />
    <meta property="og:image:height" content="800" />
    <meta property="og:image:alt" content="${TITLE}" />
    <link rel="stylesheet" href="${URLROOT}/pannellum_build/pannellum.css"/>
    <script type="text/javascript" src="${URLROOT}/pannellum_build/pannellum.js"></script>
    <style>
      html {
        height: 100%;
      }
      body {
        margin: 0;
        padding: 0;
        overflow: hidden;
        position: fixed;
        cursor: default;
        width: 100%;
        height: 100%;
      }
      #panorama {
        width: 100%;
        height: 100%;
      }
    </style>
  </head>

  <body>
    <div id="panorama"></div>
    <script>
      pannellum.viewer('panorama', {
        "title": "${TITLE}",
        "type": "equirectangular",
        "panorama": "${URLROOT}/images/${EQIMG_BASENAME}",
        "yaw": ${YAW},
        "pitch": ${PITCH},
        "autoLoad": true,
${HOTSPOTS}
      });
    </script>
  </body>

</html>
EOF

# Add an entry in the README.md
echo "[![${TITLE}](${THUMBNAIL})](${URLROOT}/${EQIMG_ROOTNAME}.html)" >> README.md
