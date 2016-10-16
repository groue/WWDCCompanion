WWDC Companion
==============

**This Swift 3 application stores, displays, and lets the user search the [WWDC 2016 sessions](https://developer.apple.com/videos/wwdc2016/).**

|         |         |         |         |
| :-----: | :-----: | :-----: | :-----: |
| ![Screen shot 1](Images/Screen1.png) | ![Screen shot 2](Images/Screen2.png) | ![Screen shot 3](Images/Screen3.png) | ![Screen shot 4](Images/Screen4.png) |

It shows how to:

- **Perform full-text search** in an SQLite database with [GRDB.swift](http://github.com/groue/GRDB.swift)
    - [Database.swift](WWDCCompanion/Models/Database.swift) initializes the SQLite database
    - [Session.swift](WWDCCompanion/Models/Session.swift) is the GRDB record that allows fetching and saving WWDC sessions in the database
    - [SearchResultsTableViewController.swift](WWDCCompanion/Controllers/SearchResultsTableViewController.swift) performs full-text search
    - [SessionsTableViewController.swift](WWDCCompanion/Controllers/SessionsTableViewController.swift) synchronizes the rows of its table view with the content of the database with a [fetched records controller](https://github.com/groue/GRDB.swift#fetchedrecordscontroller)
- **Render HTML templates** with [GRMustache.swift](https://github.com/groue/GRMustache.swift)
    - [SessionViewController.swift](WWDCCompanion/Controllers/SessionViewController.swift) renders an HTML template that renders a WWDC session
- **Parse HTML** with [Fuzi](https://github.com/cezheng/Fuzi)
