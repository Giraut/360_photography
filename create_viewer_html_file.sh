#!/bin/sh
# Call this script with the filename of the equirectangular 360 degree image for which to create an HTML file to view and its title

URLROOT=https://giraut.github.io/360_photography

# Check that we have the required arguments
if [ "$1" = "" ] || [ "$2" = "" ] || [ "$3" = "" ]; then
  echo "Usage: $0 <equirectangular file> <title> <starting pitch angle> [hotspots file]"
  exit
fi

EQIMG=$1
TITLE=$2
PITCH=$3
HOTSPOTS_FILE=$4

# If a hotspots JSON file has been specified, load it
# If it's empty, set it to "{}"
if [ "${HOTSPOTS_FILE}" != "" ] && [ -f ${HOTSPOTS_FILE} ]; then
  HOTSPOTS=$(jq . ${HOTSPOTS_FILE})
else
  HOTSPOTS={}
fi

# Determine the root name of the equirectangular image file
EQIMG_BASENAME=$(basename $EQIMG)
EQIMG_ROOTNAME=$(echo ${EQIMG_BASENAME} | sed -e "s/\.[0-9a-zA-Z]*$//")

MULTIRES=images/multires/${EQIMG_ROOTNAME}
THUMBNAIL=images/thumbnails/${EQIMG_ROOTNAME}-thumbnail.jpg

# Create the multires dataset for the source equirectangular image file if it doesn't exist yet
if ! [ -d ${MULTIRES} ]; then
  pannellum/utils/multires/generate.py --autoload --quality 85 --haov 360 --vaov 180 --hfov 100 --tilesize 1024 --fallbacksize 1024 ${EQIMG} --output ${MULTIRES}
fi

# Create the thumbnail
convert ${MULTIRES}/fallback/f.jpg -gravity center -scale x800 360_logo.png -compose over -composite ${THUMBNAIL}

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
    <link rel="stylesheet" href="pannellum_build/pannellum.css"/>
    <script type="text/javascript" src="pannellum_build/pannellum.js"></script>
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
      pannellum.viewer('panorama',
EOF

jq --indent 2 --argjson hotspots "$HOTSPOTS" '.multiRes += {"basePath": "'${MULTIRES}'"} | . += {"title": "'"${TITLE}"'", "pitch": "'"${PITCH}"'"} | . += $hotspots' ${MULTIRES}/config.json | sed -e "s/^/        /" >> ${EQIMG_ROOTNAME}.html

cat <<EOF >> ${EQIMG_ROOTNAME}.html
      );
    </script>
  </body>

</html>
EOF

# Add an entry in the README.md if it's not already there
if ! grep ${EQIMG_ROOTNAME}.html README.md > /dev/null; then
  echo "[![${TITLE}](${THUMBNAIL})](${URLROOT}/${EQIMG_ROOTNAME}.html)" >> README.md
fi
