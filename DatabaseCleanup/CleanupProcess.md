# Overview

A table that contains large object data, such as a `varbinary(max)` column, could take up a substantial and disproportionate amount of space in the database. In situations where those objects become obsolete, it may be worthwhile to purge the data and shrink the database. But, there comes a point where the delta between the original size and remaining is unmanageable to shrink through a normal database shrink process. This Database Cleanup tool leverages dbatools and SQL with the express purpose of moving the remaining data to a whole new database. It handles foreign key constraints, tables with computed columns, and conditional logic for scripting over the cleaned table. 

- Work should be performed during a designated outage window to prevent records being updated or inserted during the conversion process.
- Move the data to a new database on the same instance to reduce and network traffic latencies. 

# Process

## Shared Parameters
- `$SourceInstance`: Instance name where the current database resides.
- `$DestInstance`: Where the new database will go.
- `$SourceDatabase`: Name of source database.
- `$DestDatabase`: Name of the new database. Looks for an existing database on the destination instance. `Export-Publish-dbaDacPackage`  will create a new one if not found, but other steps will not work if no existing target.

## Create the Shell Database

For best results, restore the shell database to the same instance as the current production database and run each step from there.
1. `CreateDatabase-EmptyTemplate.sql`
    - Builds out an empty database. Any create script will do.
    - If using the sample, adjust the target data and log file sizes as needed to reflect the reduced size of the database post-cleanup.
1. `Export-Publish-dbaDacPackage.ps1`
    - Generates a dacpac of the source database, saves it to a local folder, and immediately publishes to the new database.
    - Specify the shell database as the destination.
    - Will automatically create the database if it does not already exist, but this is ill-advised.
    - See Micrsoft documentation for the full list of [Publish](https://learn.microsoft.com/en-us/sql/tools/sqlpackage/sqlpackage-publish?view=sql-server-ver16) and [Extract](https://learn.microsoft.com/en-us/sql/tools/sqlpackage/sqlpackage-extract?view=sql-server-ver16) (named Export in `dbatools`) for the full list of options. Script does not current support passing in a custom set of exclusions. The script can be manually updated to accomodate.
        - Specific Parameters:
            -  `$Path`: Folder directory for the `.dacpac`. 
            -  `$IgnorePermissions`: Export option enabled by default. Specifies whether permissions should be included.
            -  `$IgnoreUserLoginMappings`: Export option enabled by default. Specifies whether relationships between users and logins are included.
            -  `$ExcludeObjectTypes`: Publish option leveraging `/p:ExcludeObjectTypes`. Full list of options are defined in the Export resource above. Ignores certificates by default. 

## Prepare the Tables

3. `ToggleForeignKeys.sql`
    - Dynamic SQL script to generate `DROP`, `NOCHECK`, `CHECK`, and detailed information for all foreign keys.
    - Prevents foreign key conflict errors while the bulk inserts are performed.
    - Drop any foreign keys that either reference or are defined on the table being purged. Save both `DROP` and `CREATE` scripts.
    - Toggle off all other foreign keys. Run script and execute output for `NOCHECK`.
        - Parameter:
            - `@FilterTable`: Optional parameter to specify the `[schema].[table]` to only create scripts for the table getting cleaned. Ignores it if left NULL.
1. Drop non-clustered indexes on the target table in the new instance.
    - Improves performance of insert. Retaining the clustered index is a proven performance improvement for bulk insert.

## Move the Data

Each step can be run simultaneously.

5. `Copy-DbaDbTableData-LargeDataColumnCleanup.ps1`
    - Copies data from a table in the source database to the destination database.
    - Conditions can be added in the script to selectively preserve large data column.
    - Requires updating the table definition in the script which is simply a sample table.
        - Specific Data Filter Parameters:
            - `$MonthsBack`: Optional parameter to specify how many months to retain if a datetime column is available.
            - `$CutoffDate`: Optional parameter to specify a cutoff date to use for a condition copy. Set to max date by default. If `$MonthsBack` is provided, the `$CutoffDate` is overriden. 
1. `Copy-DbaDbTableData-ExcludingComputed.ps1`
    - Copies data from all tables that do not have a computed column, which prevents seamless data streaming.
    - Pass in at least the target table to the ExcludeTables array and any others to ignore in the one-to-one copy process. Currently only supports the table name with no regards to schema.
        - Specific Parameters:
            - `$ExcludeTables`: Optional array of tables to exclude in the copy. The sysdiagrams table is harded-coded to be ignored. 
1. `InsertIntoComputedColumnTables.sql`
    - Generates the `INSERT INTO` `SELECT FROM` statements, working around the computed columns, and dynamically accounting for identity insert.
    - Execute script and run output.

## Finalize the New Database

Once cleanup is complete, the database structure needs to be set back to its original state before it can be swapped in the application.

8. `ToggleForeignKeys.sql`
    - Recreate the foreign keys dropped on the cleaned table. Definitions should have been saved off when the drop statements were created.
    - Run the `RECHECK` column output for the remaining foreign keys.
1. Re-add the non-clustered indexes to the cleaned table.
1. Swap the name of the old and new databases.
1. Proceed with decomissioning source database.

