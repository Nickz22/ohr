with open("force-app/main/default/reports/AEReports-meta.xml", "r") as file:
    xml_content = file.read()

shared_to_values = []

start = 0
while True:
    start_tag = "<sharedTo>"
    end_tag = "</sharedTo>"
    start_index = xml_content.find(start_tag, start)
    if start_index == -1:
        break
    start_index += len(start_tag)
    end_index = xml_content.find(end_tag, start_index)
    shared_to = xml_content[start_index:end_index].strip()
    shared_to_values.append(shared_to)
    start = end_index + len(end_tag)

shared_to_values.sort()

output = "'" + "',\n'".join(shared_to_values) + "'"
print(output)
