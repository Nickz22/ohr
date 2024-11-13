// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

String xml = '<?xml version="1.0" encoding="UTF-8"?><Package xmlns="http://soap.sforce.com/2006/04/metadata"><types>';

Map<String, String> folderNameToDevName = new Map<String, String>();
for(Folder f : [SELECT DeveloperName, Name FROM Folder WHERE Type = 'Report']) {
    folderNameToDevName.put(f.Name, f.DeveloperName);
}
folderNameToDevName.put('Public Reports', 'unfiled$public');

Set<String> folderDevNames = new Set<String>();
for(Report r : [SELECT DeveloperName, FolderName FROM Report]) {
    String folderDevName = folderNameToDevName.get(r.FolderName);
    xml += '<members>' + folderDevName + '/' + r.DeveloperName + '</members>';
    folderDevNames.add(folderDevName);
}

xml += '<name>Report</name></types><types>';

for(String folderDevName : folderDevNames) {
    if(folderDevName != 'unfiled$public') {
        xml += '<members>' + folderDevName + '</members>';
    }
}

xml += '<name>ReportFolder</name></types><version>57.0</version></Package>';

System.debug(xml);