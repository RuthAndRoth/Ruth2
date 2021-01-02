# Shape Imports

Three of the four required wearables (shape, hair, eyes) on an avatar are included in the XML file when saving avatar appearance.  By extracting the slider values from the appearance XML we can create XML files suitable for import into a new or existing wearable.

Export avatar appearance via Firestorm menu Developer -> Avatar -> Character Tests -> Appearance To XML

When working with mesh heads and bodies it is often desirable to be able to copy the sliders for one or the other into a new shap, such as when trying out a new mesh head, you want your usual body sliders.  We can split the shape sliders into head and body subsets and create an XML file that can easily be imported to merge existing sliders into a new shape.

These import XML files are also suitable for checking into the git repository as a record of the shapes shipped with Ruth.  Creating a shape from the in-world is as simple as making a new default shape (or hair or eyes) and importing the XML files on top of that.  The shape wearable is stored here as separate head and body files so they may also be used individually.

## Extraction Script

The python script ``get-sliders.py`` extracts specific subsets of the appearance XML file.  It supports the following options:

* ``--shape``
  Extract all of the shape sliders
* ``--head``
  Extract the set of shape sliders that correspond to the avatar head
* ``--body``
  Extract the set of shape sliders that correspond to the avatar body
* ``--hair``
  Extract all of the hair sliders
* ``--eyes``
  Extract all of the eye sliders

### Installation

This script was written and tested using Python 3.  It has a single external dependency:

* lxml
