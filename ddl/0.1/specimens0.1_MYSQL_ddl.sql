-- specimens table, draft 0.1, following CLIF 3.0 and AERIE conventions.
-- Biospecimen tracking only: identity, linkage, timing, characterization, provenance, and consent.
-- Assay results are out of scope and belong in the AERIE biomarkers and omics tables, which join on specimen_id.

-- -----------------------------------------------------
-- Table: specimens
-- One row per physical container (primary specimen, derivative, or aliquot).
-- -----------------------------------------------------
CREATE TABLE specimens (
  patient_id VARCHAR COMMENT '{"description": "CLIF patient identifier and the join key to CLIF.", "permissible": "Must match patient.patient_id"}',
  study_name VARCHAR COMMENT '{"description": "Short name of the study under which the specimen was collected, e.g. VIBES.", "permissible": "No restriction"}',
  study_id VARCHAR COMMENT '{"description": "Participant identifier within the named study, e.g. VIBES-0001.", "permissible": "No restriction"}',
  specimen_label VARCHAR COMMENT '{"description": "Human-readable text printed on the container. Codes follow the processing workflow: study_id, container code and number, then derivative, biomolecule and aliquot codes, e.g. VIBES-0001-PX1-R-A1. Contains no direct identifiers or dates.", "permissible": "No restriction"}',
  specimen_id VARCHAR COMMENT '{"description": "Unique, opaque identifier for one physical container, assigned from a pre-generated label pool. Primary key of this table.", "permissible": "Unique across the table"}',
  primary_specimen_id VARCHAR COMMENT '{"description": "specimen_id of the primary specimen this row descends from. Equal to specimen_id on primary rows.", "permissible": "Must match a specimen_id in this table"}',
  specimen_class VARCHAR COMMENT '{"description": "Position of the row in the specimen lineage.", "permissible": "[primary, derivative, aliquot](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/specimens/aerie_specimens_specimen_classes.csv)"}',
  aliquot_number INT COMMENT '{"description": "Sequence number of an aliquot among aliquots of the same material. NULL unless specimen_class is aliquot.", "permissible": "Integer >= 1"}',
  specimen_name VARCHAR COMMENT '{"description": "Specimen as recorded at the site, e.g. PAXgene blood RNA tube.", "permissible": "No restriction"}',
  specimen_category VARCHAR COMMENT '{"description": "Maps specimen_name to the body compartment, following CLIF 3.0 lab_specimen_category. Inherited from the primary specimen.", "permissible": "[plasma_blood, pleural, peritoneal, urine, bal](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/specimens/aerie_specimens_specimen_categories.csv)"}',
  container_category VARCHAR COMMENT '{"description": "Type of primary collection container. Inherited from the primary specimen.", "permissible": "[paxgene_blood_rna, paxgene_blood_ccfdna, edta, sst, streck_cfdna](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/specimens/aerie_specimens_container_categories.csv)"}',
  derivative_category VARCHAR COMMENT '{"description": "Blood fraction separated by processing. NULL when the material was not fractionated, e.g. PAXgene whole blood.", "permissible": "[plasma, serum, buffy_coat](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/specimens/aerie_specimens_derivative_categories.csv)"}',
  biomolecule_category VARCHAR COMMENT '{"description": "Biomolecule extracted or isolated from the specimen. NULL when nothing was extracted.", "permissible": "[rna, dna, cfdna, protein](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/specimens/aerie_specimens_biomolecule_categories.csv)"}',
  initial_quantity_value DOUBLE COMMENT '{"description": "Quantity when the container was created.", "permissible": "Numeric >= 0"}',
  remaining_quantity_value DOUBLE COMMENT '{"description": "Quantity currently remaining. Updated each time material is used.", "permissible": "Numeric >= 0"}',
  quantity_unit VARCHAR COMMENT '{"description": "Unit for initial_quantity_value and remaining_quantity_value.", "permissible": "[mL, uL, cells](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/specimens/aerie_specimens_quantity_units.csv)"}',
  collect_dttm DATETIME COMMENT '{"description": "Date and time the primary specimen was drawn. Repeated on every row that descends from it. Anchors the specimen against clinical events in CLIF. All datetime variables must be timezone-aware and set to UTC.", "permissible": "Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC)"}',
  receipt_dttm DATETIME COMMENT '{"description": "Date and time the specimen was received by the processing laboratory. All datetime variables must be timezone-aware and set to UTC.", "permissible": "Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC)"}',
  process_start_dttm DATETIME COMMENT '{"description": "Date and time processing of this row started, defined by the protocol in protocol_name (e.g. PAXgene tube placed at -20 C; extraction started). All datetime variables must be timezone-aware and set to UTC.", "permissible": "Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC)"}',
  process_complete_dttm DATETIME COMMENT '{"description": "Date and time processing of this row was completed, defined by the protocol in protocol_name (e.g. PAXgene tube moved to -80 C; aliquots placed at -80 C). All datetime variables must be timezone-aware and set to UTC.", "permissible": "Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC)"}',
  collection_source_category VARCHAR COMMENT '{"description": "Whether the primary specimen was collected for research or is a clinical remnant. Inherited from the primary specimen.", "permissible": "[research_dedicated, remnant](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/specimens/aerie_specimens_collection_source_categories.csv)"}',
  protocol_name VARCHAR COMMENT '{"description": "Name and version of the processing SOP, e.g. PAX-SOP v1.0.", "permissible": "No restriction"}',
  processor_id VARCHAR COMMENT '{"description": "Site code or initials of the person who processed the row.", "permissible": "No restriction"}',
  storage_location VARCHAR COMMENT '{"description": "Storage location as freezer-rack-box-position, e.g. F1-R2-B04-A1. NULL for rows never stored on their own.", "permissible": "No restriction"}',
  freeze_thaw_count INT COMMENT '{"description": "Number of freeze-thaw cycles the container has undergone.", "permissible": "Integer >= 0"}',
  status_category VARCHAR COMMENT '{"description": "Current status of the container.", "permissible": "[available, reserved, depleted, shipped, destroyed](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/specimens/aerie_specimens_status_categories.csv)"}',
  irb_protocol_id VARCHAR COMMENT '{"description": "IRB protocol identifier governing the specimen under the named study.", "permissible": "No restriction"}',
  consent_category VARCHAR COMMENT '{"description": "Type of consent governing use of the specimen under the named study. Withdrawal is recorded in withdrawal_dttm, not as a category.", "permissible": "[broad_research, specific_use, opt_out, waiver_of_consent, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/specimens/aerie_specimens_consent_categories.csv)"}',
  repository_yn INT COMMENT '{"description": "Whether the participant consented to storage of the specimen in a repository for future research. 1 = yes, 0 = no.", "permissible": "0, 1"}',
  withdrawal_dttm DATETIME COMMENT '{"description": "Date and time the participant withdrew consent for repository use. NULL if not withdrawn. Specimens with a non-null value must not be used in new analyses. All datetime variables must be timezone-aware and set to UTC.", "permissible": "Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC)"}',
  PRIMARY KEY (specimen_id),
  FOREIGN KEY (patient_id) REFERENCES patient(patient_id),
  FOREIGN KEY (primary_specimen_id) REFERENCES specimens(specimen_id)
);
