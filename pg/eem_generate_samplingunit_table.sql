-- Step 1
-- CREATE a table which is going to hold feature ids and their ultimate study location entity id
-- Tom is a genius!!
DROP TABLE IF EXISTS EXT_ULTIMATE_PARENT_LOOKUP;

WITH RECURSIVE primaryfeature AS (
 SELECT
 related_feature_feature_id as entity, related_feature_feature_id as parent, related_feature_feature_id as ultimate_studylocation_entity_id
 FROM
 feature_relationship
 WHERE
 related_feature_feature_id in (select related_feature_feature_id
from feature_relationship
where related_feature_feature_id not in (select primary_feature_feature_id from feature_relationship))
 UNION
 SELECT
 child.primary_feature_feature_id, child.related_feature_feature_id, parent.ultimate_studylocation_entity_id
 FROM
 feature_relationship child	
 INNER JOIN primaryfeature parent ON parent.entity = child.related_feature_feature_id -- mosheh
) SELECT
 * INTO EXT_ULTIMATE_PARENT_LOOKUP
FROM
 primaryfeature
where entity != ultimate_studylocation_entity_id;

-- Add an id column - to play nice with SailsJs !
ALTER TABLE EXT_ULTIMATE_PARENT_LOOKUP ADD COLUMN id SERIAL PRIMARY KEY;

-- Create a helper function for cleaning data later
CREATE OR REPLACE FUNCTION eem_last_position(text,char) RETURNS integer AS $$
     select length($1)- length(regexp_replace($1, '.*' || $2,''));
$$ LANGUAGE SQL IMMUTABLE;
-- for use in e.g select substring('http:/revensthorp/R56', eem_last_position('http:/revensthorp/R56', '/') + 1);

-- Drop the main EXT_SAMPLING_UNIT table if it exists
DROP TABLE IF EXISTS EXT_SAMPLING_UNIT;
-- Start collecting data for the SamplingUnit (API)
-- Get survey metadata
-- Load it into the EXT_SAMPLING_UNIT table
-- Note: This table will correspond to the model in Sailsjs
SELECT observation.feature_feature_id as sampledarea_samplingunit_entity_id, EXT_ULTIMATE_PARENT_LOOKUP.ultimate_studylocation_entity_id as studylocation_entity_id,
metadata.custodian, metadata.rights, metadata.citation as bibliographic_reference, metadata.date_modified, metadata.language, metadata.persistentsurvey_id as surveyid, metadata.survey_name,
metadata.organisation as survey_organisation, metadata.licence
INTO EXT_SAMPLING_UNIT
from observation, EXT_ULTIMATE_PARENT_LOOKUP, survey_link, metadata
where observation.feature_feature_id like '%SAMPL%' AND observation.feature_feature_id = EXT_ULTIMATE_PARENT_LOOKUP.entity AND EXT_ULTIMATE_PARENT_LOOKUP.ultimate_studylocation_entity_id = survey_link.study_location_feature_id AND
survey_link.metadata_survey_id = metadata.survey_id;

ALTER TABLE EXT_SAMPLING_UNIT
 --ADD COLUMN id SERIAL PRIMARY KEY,
 ADD COLUMN id BIGSERIAL PRIMARY KEY,
 ADD COLUMN survey_type VARCHAR, -- Not available yet
 ADD COLUMN survey_methodology VARCHAR, -- Not available yet
 ADD COLUMN survey_methodology_description VARCHAR, -- Not available yet
 ADD COLUMN studylocation_id VARCHAR,
 ADD COLUMN orginal_site_code VARCHAR,
 ADD COLUMN province VARCHAR, -- Not available yet
 ADD COLUMN geodetic_datum VARCHAR,
 ADD COLUMN latitude VARCHAR,
 ADD COLUMN longitude VARCHAR,
 ADD COLUMN location_description VARCHAR, -- Not available yet
 ADD COLUMN aspect VARCHAR, -- Not available yet
 ADD COLUMN slope VARCHAR, -- Not available yet
 ADD COLUMN landform_pattern VARCHAR, -- Not available yet
 ADD COLUMN landform_element VARCHAR, -- Not available yet
 ADD COLUMN elevation VARCHAR, -- Not available yet
 ADD COLUMN visit_id VARCHAR, -- Not available yet
 ADD COLUMN visit_date VARCHAR, -- Not available yet
 ADD COLUMN visit_organisation VARCHAR, -- Not available yet
 ADD COLUMN visit_observers VARCHAR, -- Not available yet
 ADD COLUMN site_description VARCHAR, -- Not available yet
 ADD COLUMN condition VARCHAR, -- Not available yet
 ADD COLUMN structural_form VARCHAR, -- No available
 ADD COLUMN owner_classification VARCHAR, -- Not available yet
 ADD COLUMN current_classification VARCHAR, -- Not available yet
 ADD COLUMN sampling_unit_id VARCHAR, --Is this the entity id or something else?
 ADD COLUMN sampling_unit_area VARCHAR,
 ADD COLUMN sampling_unit_shape VARCHAR;

 --Clean some field data
 UPDATE EXT_SAMPLING_UNIT SET custodian = trim (both '"' from custodian);
 UPDATE EXT_SAMPLING_UNIT SET rights = trim (both '"' from rights);
 UPDATE EXT_SAMPLING_UNIT SET bibliographic_reference = trim (both '"' from bibliographic_reference);
 UPDATE EXT_SAMPLING_UNIT SET date_modified = trim (both '"' from substring(date_modified, 1, position('^' in date_modified) -1));
 UPDATE EXT_SAMPLING_UNIT SET bibliographic_reference = trim (both '"' from bibliographic_reference);
 UPDATE EXT_SAMPLING_UNIT SET language = trim (both '"' from language);
 UPDATE EXT_SAMPLING_UNIT SET surveyid = trim (both '"' from surveyid);
 UPDATE EXT_SAMPLING_UNIT SET survey_name = trim (both '"' from survey_name);
 UPDATE EXT_SAMPLING_UNIT SET survey_organisation = trim (both '"' from survey_organisation);
 UPDATE EXT_SAMPLING_UNIT SET licence = trim (both '"' from licence);


-- Get studylocation ids (not entity id)
-- e.g aekos.org.au/collection/wa.gov.au/ravensthorpe/R001
-- Load them into a temp table: TEMP_STUDYLOCATION_IDS_DATA
SELECT DISTINCT observation.feature_feature_id as studylocation_entity_id,result.value AS studylocation_id
INTO TEMP_STUDYLOCATION_IDS_DATA FROM observation, lut_property_type, EXT_ULTIMATE_PARENT_LOOKUP, observation_results, result
where observation.feature_feature_id = EXT_ULTIMATE_PARENT_LOOKUP.ultimate_studylocation_entity_id AND observation.property_property_type_id = lut_property_type.property_type_id AND lut_property_type.name = 'Identifier'
AND observation.observation_id = observation_results.observation_observation_id AND observation_results.results_result_id = result.result_id and result.element = 'Value';

-- Update studylocation id in: EXT_SAMPLING_UNIT
UPDATE EXT_SAMPLING_UNIT SET studylocation_id = trim(both '"' from (SELECT studylocation_id from TEMP_STUDYLOCATION_IDS_DATA where EXT_SAMPLING_UNIT.studylocation_entity_id = TEMP_STUDYLOCATION_IDS_DATA.studylocation_entity_id));

-- Update original study location code field in: EXT_SAMPLING_UNIT
UPDATE EXT_SAMPLING_UNIT SET orginal_site_code = trim (both '"' from substring(studylocation_id, eem_last_position(studylocation_id, '/') + 1));

--Drop the TEMP_STUDYLOCATION_IDS_DATA table - we are done with it
DROP TABLE IF EXISTS TEMP_STUDYLOCATION_IDS_DATA;


--Get location of studylocation
-- Load it in the temp table: TEMP_STUDYLOCATION_LOCATION_DATA
SELECT DISTINCT observation.feature_feature_id as studylocation_entity_id,result.element, result.value
INTO TEMP_STUDYLOCATION_LOCATION_DATA FROM observation, lut_property_type, EXT_ULTIMATE_PARENT_LOOKUP, observation_results, result
where observation.feature_feature_id = EXT_ULTIMATE_PARENT_LOOKUP.ultimate_studylocation_entity_id AND observation.property_property_type_id = lut_property_type.property_type_id AND lut_property_type.name = 'Location'
AND observation.observation_id = observation_results.observation_observation_id AND observation_results.results_result_id = result.result_id AND result.element <> 'Type' ORDER BY observation.feature_feature_id;

--Update Geo Datum field of: EXT_SAMPLING_UNIT table
UPDATE EXT_SAMPLING_UNIT SET geodetic_datum = (SELECT value from TEMP_STUDYLOCATION_LOCATION_DATA where EXT_SAMPLING_UNIT.studylocation_entity_id = TEMP_STUDYLOCATION_LOCATION_DATA.studylocation_entity_id AND
TEMP_STUDYLOCATION_LOCATION_DATA.element = 'Datum');

--Update latutude field: in EXT_SAMPLING_UNIT table
UPDATE EXT_SAMPLING_UNIT SET latitude = (SELECT value from TEMP_STUDYLOCATION_LOCATION_DATA where EXT_SAMPLING_UNIT.studylocation_entity_id = TEMP_STUDYLOCATION_LOCATION_DATA.studylocation_entity_id AND
TEMP_STUDYLOCATION_LOCATION_DATA.element = 'Latitude');

-- Update longitude field: in EXT_SAMPLING_UNIT table
UPDATE EXT_SAMPLING_UNIT SET longitude = (SELECT value from TEMP_STUDYLOCATION_LOCATION_DATA where EXT_SAMPLING_UNIT.studylocation_entity_id = TEMP_STUDYLOCATION_LOCATION_DATA.studylocation_entity_id AND
TEMP_STUDYLOCATION_LOCATION_DATA.element = 'Longitude');

--Drop TEMP_STUDYLOCATION_LOCATION_DATA table
DROP TABLE IF EXISTS TEMP_STUDYLOCATION_LOCATION_DATA;

-- Get sampledArea or samplingUnit size
-- Load them into a temp table TEMP_SAMPLE_AREA_DATA
SELECT observation.feature_feature_id as sampledarea_samplingunit_entity_id, EXT_ULTIMATE_PARENT_LOOKUP.ultimate_studylocation_entity_id as studylocation_entity_id, result.element, result.value
INTO TEMP_SAMPLE_AREA_DATA from observation,lut_property_type, EXT_ULTIMATE_PARENT_LOOKUP, observation_results, result  where
observation.property_property_type_id = lut_property_type.property_type_id and lut_property_type.name = 'Area'
and observation.feature_feature_id = EXT_ULTIMATE_PARENT_LOOKUP.entity and
observation.observation_id = observation_results.observation_observation_id and
observation_results.results_result_id = result.result_id ORDER BY observation.feature_feature_id desc;
-- Update the Sampling unit id  filed in EXT_SAMPLING_UNIT
-- Note: not sure where this data is but for now I am just loading the entity id of the sampledArea or Sampling unit
-- Squid needs to clarify
UPDATE EXT_SAMPLING_UNIT SET sampling_unit_id = (SELECT sampledarea_samplingunit_entity_id FROM TEMP_SAMPLE_AREA_DATA WHERE TEMP_SAMPLE_AREA_DATA.sampledarea_samplingunit_entity_id = EXT_SAMPLING_UNIT.sampledarea_samplingunit_entity_id
AND TEMP_SAMPLE_AREA_DATA.element = 'Type');

--Update the sampling unit area field and clean data
UPDATE EXT_SAMPLING_UNIT SET sampling_unit_area = trim(both '"' from (SELECT value FROM TEMP_SAMPLE_AREA_DATA WHERE TEMP_SAMPLE_AREA_DATA.sampledarea_samplingunit_entity_id = EXT_SAMPLING_UNIT.sampledarea_samplingunit_entity_id
AND TEMP_SAMPLE_AREA_DATA.element = 'Value'));

-- Clean the values
UPDATE EXT_SAMPLING_UNIT SET sampling_unit_area = trim (both '"' from substring(sampling_unit_area, 1, position('^' in sampling_unit_area) -1));

--Update the sampling unit shape field
-- And clean the data
UPDATE EXT_SAMPLING_UNIT SET sampling_unit_shape = trim(both '"' from (SELECT value FROM TEMP_SAMPLE_AREA_DATA WHERE TEMP_SAMPLE_AREA_DATA.sampledarea_samplingunit_entity_id = EXT_SAMPLING_UNIT.sampledarea_samplingunit_entity_id
AND TEMP_SAMPLE_AREA_DATA.element = 'Standard'));

--Drop TEMP_SAMPLE_AREA_DATA table
DROP TABLE IF EXISTS TEMP_SAMPLE_AREA_DATA;

--END