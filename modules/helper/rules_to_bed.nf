process RULES_TO_BED {

    input:
    path(json)

    output:
    path(bed), emit: bed

    script:
    bed = "rules.txt"

    """
    rules_to_bed.rb --json $json > $bed
    """

}