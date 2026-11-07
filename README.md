# AERIE_Specimen: biospecimen tracking and linkage table

A CLIF-style table for tracking research biospecimens: what was collected, from whom, under which study and consent, how it was processed, and where it is now. One row per physical container: the parent specimen, each derivative, and each aliquot of either the parent or derivative.

This table covers tracking and linkage only. Assay runs (proposed title: AERIE_Assay) and analyte results (proposed title: AERIE_Analyte) are reported separately, which join to this table on `specimen_id`.

## Structure

Each row carries six domains:

| Domain | Columns |
|---|---|
| Identity | `specimen_label`, `specimen_id` |
| Linkage | `patient_id`, `study_name`, `study_id`, `parent_specimen_id` |
| Characterization | `specimen_class`, `aliquot_number`, `specimen_name`, `specimen_category`, `container_category`, `derivative_category`, `biomolecule_category`, `initial_quantity_value`, `remaining_quantity_value`, `quantity_unit` |
| Timing | `collect_dttm`, `receipt_dttm`, `process_start_dttm`, `process_complete_dttm` |
| Provenance | `collection_source_category`, `protocol_name`, `processor_id`, `storage_location`, `freeze_thaw_count`, `status_category` |
| Consent | `irb_protocol_id`, `consent_category`, `withdrawal_dttm` |

**Lineage.** `specimen_class` identifies a row as parent, derivative, or aliquot. `parent_specimen_id` points every row to the original tube drawn from the patient from which it descended, so one filter returns everything from a single draw. `specimen_label` records the processing path in workflow order: VIBES-0001-PX1-R-A1 is aliquot 1 of RNA extracted from PAXgene tube 1. Depleted parents and transient derivatives keep their rows so lineage stays complete.

**What a container holds** is described at three levels: compartment (`specimen_category` matching CLIF fluid_category conventions), derivative (`derivative_category`), and extracted biomolecule (`biomolecule_category`). For example, PAXgene RNA is `plasma_blood` / NA / `rna`; a plasma aliquot from an EDTA tube is `plasma_blood` / `plasma` / NA.

**Example**

| specimen_id | specimen_label | primary_specimen_id | specimen_class | aliquot_number | container_category | derivative_category | biomolecule_category | status_category |
|---|---|---|---|---|---|---|---|---|
| V000101 | VIBES-0001-PX1 | V000101 | primary | | paxgene_blood_rna | | | depleted |
| V000102 | VIBES-0001-PX1-R | V000101 | derivative | | paxgene_blood_rna | | rna | depleted |
| V000103 | VIBES-0001-PX1-R-A1 | V000101 | aliquot | 1 | paxgene_blood_rna | | rna | available |
| V000104 | VIBES-0001-PX1-R-A2 | V000101 | aliquot | 2 | paxgene_blood_rna | | rna | shipped |

## Conventions

The table follows CLIF 3.0. Raw strings go in `*_name` columns and map to controlled vocabularies in `*_category` columns. Category values are lowercase snake_case, except UCUM units (`mL`, `uL`). Every datetime is timezone-aware UTC, `YYYY-MM-DD HH:MM:SS+00:00`. Binary fields are INT 0/1. `specimen_category` uses the CLIF 3.0 `fluid_category` vocabulary. Columns that describe the draw (`collect_dttm`, `specimen_category`, `container_category`, `collection_source_category`) are repeated on every row from that draw.

## Columns

| Column | Type | Required | Description | Permissible values |
|---|---|---|---|---|
| `patient_id` | VARCHAR | yes | CLIF patient identifier and the join key to CLIF. | Must match patient_id |
| `study_name` | VARCHAR | yes | Short name of the study under which the specimen was collected, e.g. VIBES. | No restriction |
| `study_id` | VARCHAR | yes | Participant identifier within the named study, e.g. VIBES-0001. | No restriction |
| `specimen_label` | VARCHAR | yes | Human-readable text printed on the container. Codes follow the processing workflow: study_id, container code and number, then derivative, biomolecule and aliquot codes, e.g. VIBES-0001-PX1-R-A1. Contains no direct identifiers or dates. | No restriction |
| `specimen_id` | VARCHAR | yes | Unique identifier for one physical container. Primary key of this table. | Unique across the table |
| `parent_specimen_id` | VARCHAR | yes | specimen_id of the parent specimen this row descends from. Equal to specimen_id on parent rows. | Must match a specimen_id in this table |
| `specimen_class` | VARCHAR | yes | Position of the row in the specimen lineage. | [primary, derivative, aliquot](mCIDE/specimens/aerie_specimens_specimen_classes.csv) |
| `aliquot_number` | INT |  | Sequence number of an aliquot among aliquots of the same material. NULL unless specimen_class is aliquot. | Integer >= 1 |
| `specimen_name` | VARCHAR |  | Specimen as recorded at the site, e.g. PAXgene blood RNA tube. | No restriction |
| `specimen_category` | VARCHAR | yes | Maps specimen_name to the body compartment, following CLIF 3.0 fluid_category. Inherited from the parent specimen. | [plasma_blood, pleural, peritoneal, urine, bal](mCIDE/specimens/aerie_specimens_specimen_categories.csv) |
| `container_category` | VARCHAR | yes | Type of primary collection container. Inherited from the parent specimen. | [paxgene_blood_rna, paxgene_blood_ccfdna, edta, sst, streck_cfdna](mCIDE/specimens/aerie_specimens_container_categories.csv) |
| `derivative_category` | VARCHAR |  | Blood fraction separated by processing. NULL when the material was not fractionated. | [plasma, serum, buffy_coat](mCIDE/specimens/aerie_specimens_derivative_categories.csv) |
| `biomolecule_category` | VARCHAR |  | Biomolecule extracted or isolated from the specimen. NULL when nothing was extracted. | [rna, dna, cfdna, protein](mCIDE/specimens/aerie_specimens_biomolecule_categories.csv) |
| `initial_quantity_value` | DOUBLE |  | Quantity when the container was created. | Numeric >= 0 |
| `remaining_quantity_value` | DOUBLE |  | Quantity currently remaining. Updated each time material is used. | Numeric >= 0 |
| `quantity_unit` | VARCHAR |  | Unit for initial_quantity_value and remaining_quantity_value. | [mL, uL, cells](mCIDE/specimens/aerie_specimens_quantity_units.csv) |
| `collect_dttm` | DATETIME | yes | Date and time the primary specimen was drawn. Repeated on every row that descends from it. Anchors the specimen against clinical events in CLIF. All datetime variables must be timezone-aware and set to UTC. | Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC) |
| `receipt_dttm` | DATETIME |  | Date and time the specimen was received by the processing laboratory. All datetime variables must be timezone-aware and set to UTC. | Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC) |
| `process_start_dttm` | DATETIME |  | Date and time processing of this row started, defined by the protocol in protocol_name (e.g. PAXgene tube placed at -20 C; extraction started). All datetime variables must be timezone-aware and set to UTC. | Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC) |
| `process_complete_dttm` | DATETIME |  | Date and time processing of this row was completed, defined by the protocol in protocol_name (e.g. PAXgene tube moved to -80 C; aliquots placed at -80 C). All datetime variables must be timezone-aware and set to UTC. | Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC) |
| `collection_source_category` | VARCHAR |  | Whether the primary specimen was collected for research or is a clinical remnant. Inherited from the primary specimen. | [research_dedicated, remnant](mCIDE/specimens/aerie_specimens_collection_source_categories.csv) |
| `protocol_name` | VARCHAR |  | Name and version of the processing SOP, e.g. PAX-SOP v1.0. | No restriction |
| `sprec_code` | VARCHAR |  | SPREC 3.0 fluid code for the specimen as stored: seven elements separated by hyphens (type of sample, primary container, pre-centrifugation, centrifugation, second centrifugation, post-centrifugation delay, long-term storage), e.g. BLD-PAX-C-N-N-N-Y for a PAXgene tube stored at -80 C. Set from the SOP named in protocol_name and changed when processing deviates. NULL for nucleic acid derivatives and their aliquots, which SPREC does not code. | [SPREC 3.0 code lists](mCIDE/specimens/aerie_specimens_sprec_codes.csv) |
| `processor_id` | VARCHAR |  | Site code or initials of the person who processed the row. | No restriction |
| `storage_location` | VARCHAR |  | Storage location as freezer-rack-box-position, e.g. F1-R2-B04-A1. NULL for rows never stored on their own. | No restriction |
| `freeze_thaw_count` | INT |  | Number of freeze-thaw cycles the container has undergone. | Integer >= 0 |
| `status_category` | VARCHAR | yes | Current status of the container. | [available, reserved, depleted, shipped, destroyed](mCIDE/specimens/aerie_specimens_status_categories.csv) |
| `irb_protocol_id` | VARCHAR | yes | IRB protocol identifier governing the specimen under the named study. | No restriction |
| `consent_category` | VARCHAR | yes | Type of consent governing use of the specimen under the named study. Withdrawal is recorded in withdrawal_dttm, not as a category. | [broad_research, specific_use, opt_out, waiver_of_consent, other](mCIDE/specimens/aerie_specimens_consent_categories.csv) |
| `withdrawal_dttm` | DATETIME |  | Date and time the participant withdrew consent for repository use. NULL if not withdrawn. Specimens with a non-null value must not be used in new analyses. All datetime variables must be timezone-aware and set to UTC. | Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC) |

## Open questions

- `specimen_category` follows CLIF 3.0 (`plasma_blood`, ...); the AERIE results tables use their own list (`blood`, ...). The two should converge.
- `consent_category` drops AERIE's `withdrawn`, because withdrawal is recorded in `withdrawal_dttm` and a withdrawn code would overwrite the original consent type.
