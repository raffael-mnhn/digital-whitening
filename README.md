# digital-whitening
A GIMP script-fu (scheme) digital whitening plugin according to D.N. Kiselev 2021.

## Installation
Drop the digital-whitening.scm file into your GIMP script location (Look in `Edit>Preferences>Folders>Scripts`). You should then re-load the scripts using `Filters>Script-Fu>Refresh Scripts`. After this, a new Menu-item should appear: `Script-Fu>Paleontology>Digital Whitening`.

## Usage
Select the base image. This will be used as positive image. It should have good shadows. Then select a directory with the other images. It can also be the directory containing the base image, in this case the base base image will conveniently not be used as overlay image. Adjust the selection threshold to select the background more aggressively (larger value) or less aggressively (smaller value). 

The expansion value adjusts the histogram curve. Small values do aggressive histogram expansion (contrast is strongly enhanced) while values close to 1 do little effect. You can switch off the expansion completely.

You can select if you want the layers to be flattened.

## Non-interactive use
`$ gimp -idfsc --no-shm --batch='(digital-whitening #f "./out.png" "./NW.jpg" "." "*.jpg" 3.5 0.2 1 1)'` while replacing the parameters as you see fit. The first parameter needs to be `#f` indicating non-interactive use.
