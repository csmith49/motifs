SELECT target FROM (
    SELECT id as anchor FROM TEXT WHERE value="Place of Birth"
) JOIN LEFT_OF ON source=anchor;