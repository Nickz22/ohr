import xml.etree.ElementTree as ET
import sys


def merge_profiles(am_path, hybrid_path):
    am_tree = ET.parse(am_path)
    hybrid_tree = ET.parse(hybrid_path)
    am_root = am_tree.getroot()
    hybrid_root = hybrid_tree.getroot()
    for section_name in [
        "userPermissions",
        "objectPermissions",
        "fieldPermissions",
        "recordTypeVisibilities",
        "tabVisibilities",
        "classAccesses",
        "pageAccesses",
        "applicationVisibilities",
    ]:
        for am_section in am_root.findall(section_name):
            am_name = (
                am_section.find("name").text
                if am_section.find("name") is not None
                else None
            )
            if am_name and not any(
                x.find("name").text == am_name
                for x in hybrid_root.findall(section_name)
            ):
                hybrid_root.append(am_section)
    hybrid_tree.write(hybrid_path, encoding="UTF-8", xml_declaration=True)


if __name__ == "__main__":
    merge_profiles(sys.argv[1], sys.argv[2])
