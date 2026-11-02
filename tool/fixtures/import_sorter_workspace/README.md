This nested Dart workspace contains an intentionally unsorted import template.
The workspace checker copies it to a temporary package and confirms that the
import sorter detects the ordering issue without adding it to workspace
analysis or normal import checks.
