# What this does
Converts CFIS reports to tables of data to use with excel etc.

# Future TODO
 - Should create a function that scans the first row lines of the schedule and returns a list of the locations of the important data items
 - this list is then fed back in to the clean up function.
 - might make it easier to update if there are changes to the schedule formats.

# Version History
 - Version 1.4.0 - Tested 1.3.3 and seems to work so set as new version.
 - Version 1.3.3 - Fixed extra amount column appearing when converting to $ from $000
 - Version 1.3.2 - Now reads multiple columns of amount data so you can pull 3 comparator columns and it will separate them out.
 - Version 1.3.1 - renamed output columns to prefix with 'c2d' to reduce chance of column name collision on merge with mapping table.
 - Version 1.3.0 - 1.3.x series development version to add features
 - Version 1.2.0 - working with one column of amount data using Exercise Advanced Comparison output


