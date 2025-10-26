# Description

The app allows to search compounds through ‘PubChem’ and helps to keep information on solutions made of those compounds.

* The app is written and tested on `Swift 4.1` and `Xcode 9.3`.
* The app is available on App Store.

[<img src="./docs/assets/images/App_Store_Badge.svg">](https://itunes.apple.com/us/app/search-pubchem/id1369742632?mt=8)

# Installation

1. Clone or download the repository: [https://github.com/jaeseung16/SearchPubChem.git](https://github.com/jaeseung16/SearchPubChem.git)
2. Open `SearchPubChem.xcodeproj` in Xcode
3. Build and run

# How to Use

## Compounds Tab

Search the open chemistry database ‘PubChem’ at the National Institutes of Health (NIH) for chemical compounds. The app helps to find a compound by name from the collection of more than 90 million compounds. It downloads and stores the molecular formula, weight, and structure.

### Compounds

1. Selecting the **Compounds** tab will present a table of compounds.
  - If there are any solutions made of a compound, 💧 will appear next to the compound's name.
2. When a compound is selected, a view with the detailed information will appear. Follow the instruction in **Details for a compound**.
3. When the **+** button is selected, a view for search will appear. Follow the instruction in **Search for a compound**.

### Details for a compound

1. Click **<Compounds** to return back to the table of compounds.
2. Click the **magnifier** icon to open the PubChem page for the compound.
3. Click the **trashcan** icon to delete the compound. This function may not be available if there is a solution made of the compound.
4. Click one of the solutions made of the compound to display the information. See **Details for a solution** below.

### Search for a compound

1. Type a compound name into the text field, which is filled with ‘water’ by default.
2. Click **Search** to begin searching the database. An activity indicator will appear until the search is finished.
  - If the search succeeds, the downloaded information will appear.
  - If the search fails, an alert will appear.
3. Click **Save** to store the information about a compound.
4. Click **Cancel** anytime to dismiss the scene.

## Solutions Tab

Choose compounds downloaded from PubChem and make a solution. The app allows to record a list of compounds with amounts dissolved in a solution. For the saved solutions, the app displays their compositions in gram and mol.

### Solutions

1. Selecting the **Solutions** tab will present a table of solutions.
2. When a solution is selected, a view with the detailed information will appear. Follow the instruction in **Details for a solution**.
3. When the **+** button is selected, a view for search will appear. Follow the instruction in **Making a solution**.

### Details for a solution

1. Click **<Solutions** to return back to the table of compounds.
2. Click the **action** icon to share a csv file containig the information about the solution.
3. Click the **trashcan** icon to delete the solution.
4. Choose between *actual* and *%* to display the actual or percent amounts of individual compounds.
5. Choose the unit between `gram` and `mol`.
  - When *gram* is selected, *actual* displays the amounts in the unit of gram or *%* does in the percentage of weights.
  - When *mol* is selected, *actual* displays the amounts in the unit of mol or *%* does in the percentage of the number of molecules.
6. Select one of compounds to display its structure and formula. See **Mini details for a compound** below.

### Making a solution

1. Enter a label for a new soltion.
2. Click **Add Compounds** to bring a collection of compounds. See **Compounds collection** below.
3. The names of the compounds selected from **Compounds collection** will be displayed in the table view.
4. The unit for the amount can be chosen among *gram*, *mg*, *mol*, and *mM*.
5. The amount may be entered.
6. Click **Save** to create and add a new solution.
7. Click **Cancel** anytime to dismiss the scene.

### Compounds collection

1. Select or deselect compounds by clicking the images of compounds.
2. Selected compounds will be displayed.
3. Click **+** to bring a view for searching a compound. See **Search for a compound**.
4. Click **Done** to return back to **Making a solution**.
5. Click **Cancel** anytime to dismiss the scene.

### Mini details for a compound

1. Click **Done** to return back to **Details for a solution**.


## Version History

### ver 4.2 (12/9/2023)
1. Support splotlight search: A user can turn the feature on/off through Settings
2. The 3D structure display can be reset to go back to the original viewpoint.

### ver 4.1 (6/19/2023)
1. Notification and Widget are available
2. Search compound by name

### ver 4.0 (10/27/2021)
1. The data can be shared between multiple devices if iCloud is enabled

### ver 3.0 (6/14/2021)
1. Compounds can be searched by PubChem CID (compound identification number)
2. Compounds can be tagged

### ver 2.1 (8/1/2020)

1. Fix the 'magnifier' icon for opening the PubChem page for the compound
2. Enhance JSON parsing using Codable types
3. Update the interface for iPad

### ver 2.0 (11/9/2019)

1. Supporting 3D conformers
   - If a 3D conformer is available from PubChem, it will be downloaded. Check whether "Conformer" appears at the bottom of the image downloaded after a search is finished. Also, check whether "3D" appears at the upper right corner of the image of a molecule. The conformer scene supports the pan and pinch gestures!
2. Supporting the dark mode

### ver 1.0 (Apr 11, 2018)
