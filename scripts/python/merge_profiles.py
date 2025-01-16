# This script merges two Salesforce profile XML files.
# Usage: python merge_profiles.py <AE_profile_path> <AM_profile_path> <Hybrid_profile_path>

import xml.etree.ElementTree as ET
import sys
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

NS = "{http://soap.sforce.com/2006/04/metadata}"


def register_namespaces():
    ET.register_namespace("", "http://soap.sforce.com/2006/04/metadata")


def strip_namespace(elem):
    if elem.tag.startswith("{"):
        elem.tag = elem.tag.split("}")[1]
    for c in elem:
        strip_namespace(c)


def extract_unique_tags(file_path):
    tree = ET.parse(file_path)
    root = tree.getroot()
    unique_tags = set()

    def find_unique_tags(element):
        tag_name = element.tag
        unique_tags.add(tag_name)
        for child in element:
            find_unique_tags(child)

    find_unique_tags(root)
    logger.info(f"Found {len(unique_tags)} unique tags in {file_path}")
    return unique_tags


def element_to_string(elem):
    return ET.tostring(elem, encoding="unicode")


def merge_profiles(profile_path1, profile_path2, hybrid_path):
    register_namespaces()
    logger.info(
        f"Starting merge process with:\nProfile 1: {profile_path1}\nProfile 2: {profile_path2}\nHybrid: {hybrid_path}"
    )

    hybrid_tree = ET.parse(hybrid_path)
    hybrid_root = hybrid_tree.getroot()
    logger.info(f"Successfully loaded hybrid profile with root tag: {hybrid_root.tag}")

    tags1 = extract_unique_tags(profile_path1)
    tags2 = extract_unique_tags(profile_path2)
    logger.info(f"Profile 1 unique tags: {len(tags1)}")
    logger.info(f"Profile 2 unique tags: {len(tags2)}")

    unique_tags = tags1.union(tags2)
    logger.info(f"Combined unique tags: {len(unique_tags)}")

    changes_made = 0
    for path in [profile_path1, profile_path2]:
        logger.info(f"Processing profile: {path}")
        tree = ET.parse(path)
        root = tree.getroot()

        for section_name in unique_tags:
            sections = root.findall(section_name)
            if sections:
                logger.info(f"Found {len(sections)} sections with tag {section_name}")

            for section in sections:
                name_elem = section.find(f"{NS}name")
                if name_elem is None:
                    name_elem = section.find("name")
                name_val = name_elem.text if name_elem is not None else None

                if name_val:
                    matching_sections = hybrid_root.findall(section_name)
                    existing_section = None
                    for x in matching_sections:
                        x_name = x.find(f"{NS}name")
                        if x_name is None:
                            x_name = x.find("name")
                        if x_name is not None and x_name.text == name_val:
                            existing_section = x
                            break

                    if existing_section is None:
                        logger.info(
                            f"Adding new section {section_name} with name {name_val}"
                        )
                        logger.debug(
                            f"New section content: {element_to_string(section)}"
                        )
                        hybrid_root.append(section)
                        changes_made += 1
                    else:
                        section_str = element_to_string(section)
                        existing_str = element_to_string(existing_section)
                        if section_str != existing_str:
                            logger.info(
                                f"Replacing section {section_name} with name {name_val} due to content difference"
                            )
                            logger.debug(f"Old content: {existing_str}")
                            logger.debug(f"New content: {section_str}")
                            hybrid_root.remove(existing_section)
                            hybrid_root.append(section)
                            changes_made += 1

    logger.info(f"Total changes made: {changes_made}")
    hybrid_tree.write(hybrid_path, encoding="UTF-8", xml_declaration=True)
    logger.info("Merge completed and file written")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        logger.error("Incorrect number of arguments")
        logger.info(
            "Usage: python merge_profiles.py <AE_profile_path> <AM_profile_path> <Hybrid_profile_path>"
        )
        sys.exit(1)
    merge_profiles(sys.argv[1], sys.argv[2], sys.argv[3])
