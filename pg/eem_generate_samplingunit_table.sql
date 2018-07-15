-- Step 1
-- CREATE a table which is going to hold feature id and its ultimate study location entity id
-- Tom is a genius!!
--WITH RECURSIVE primaryfeature AS ( 
--    SELECT
--         related_feature_feature_id as entity,
--         related_feature_feature_id as parent,
--         related_feature_feature_id as ultimate 
--    FROM feature_relationship 
 --   WHERE
 --        related_feature_feature_id in (
 --       select
--             related_feature_feature_id 
--        from feature_relationship 
--        where
 --            related_feature_feature_id not in (
 --           select
 --                primary_feature_feature_id 
--            from feature_relationship)) 
--    UNION 
--    SELECT
--         child.primary_feature_feature_id,
--        child.related_feature_feature_id,
--         parent.ultimate 
--    FROM feature_relationship child INNER JOIN
--         primaryfeature parent ON parent.entity = child.related_feature_feature_id -- mosheh ) SELECT  * INTO EX_ULTIMATE_PARENT_LOOKUP FROM  primaryfeature where entity != ultimate

--ALTER TABLE EX_ULTIMATE_PARENT_LOOKUP ADD COLUMN id SERIAL PRIMARY KEY;



CREATE OR REPLACE FUNCTION aekos_last_post(text,char) RETURNS integer AS $$ 
     select length($1)- length(regexp_replace($1, '.*' || $2,''));
$$ LANGUAGE SQL IMMUTABLE;
-- for use in e.g select substring('http:/revensthorp/R56', aekos_last_post('http:/revensthorp/R56', '/') + 1);

-- Drop EXT_SAMPLING_UNIT table if it exists
DROP TABLE IF EXISTS EXT_SAMPLING_UNIT;
-- Get survey metadata
-- Load it into the EXT_SAMPLING_UNIT table
-- Note: This table will correspond to the model in Sailsjs
SELECT observation.feature_feature_id as sampledarea_samplingunit_entity_id, ex_ultimate_parent_lookup.ultimate as studylocation_entity_id,
metadata.custodian, metadata.rights, metadata.citation as bibliographic_reference, metadata.date_modified, metadata.language, metadata.persistentsurvey_id as surveyid, metadata.survey_name, 
metadata.organisation as survey_organisation, metadata.licence 
INTO EXT_SAMPLING_UNIT  
from observation, ex_ultimate_parent_lookup, survey_link, metadata 
where observation.feature_feature_id like '%SAMPL%' AND observation.feature_feature_id = ex_ultimate_parent_lookup.entity AND ex_ultimate_parent_lookup.ultimate = survey_link.study_location_feature_id AND
survey_link.metadata_survey_id = metadata.survey_id;

ALTER TABLE EXT_SAMPLING_UNIT 
 --ADD COLUMN id SERIAL PRIMARY KEY,
 ADD COLUMN id BIGSERIAL PRIMARY KEY,
 ADD COLUMN survey_type VARCHAR, -- No available
 ADD COLUMN survey_methodology VARCHAR, -- No available
 ADD COLUMN survey_methodology_description VARCHAR, -- No available
 ADD COLUMN studylocation_id VARCHAR,
 ADD COLUMN orginal_site_code VARCHAR,
 ADD COLUMN province VARCHAR, -- No available
 ADD COLUMN geodetic_datum VARCHAR,
 ADD COLUMN latitude VARCHAR,
 ADD COLUMN longitude VARCHAR,
 ADD COLUMN location_description VARCHAR, -- No available
 ADD COLUMN aspect VARCHAR, -- No available
 ADD COLUMN slope VARCHAR, -- No available
 ADD COLUMN landform_pattern VARCHAR, -- No available
 ADD COLUMN landform_element VARCHAR, -- No available
 ADD COLUMN elevation VARCHAR, -- No available
 ADD COLUMN visit_id VARCHAR, -- No available
 ADD COLUMN visit_date VARCHAR, -- No available
 ADD COLUMN visit_organisation VARCHAR, -- No available
 ADD COLUMN visit_observers VARCHAR, -- No available
 ADD COLUMN site_description VARCHAR, -- No available
 ADD COLUMN condition VARCHAR, -- No available
 ADD COLUMN structural_form VARCHAR, -- No available
 ADD COLUMN owner_classification VARCHAR, -- No available
 ADD COLUMN current_classification VARCHAR, -- No available
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
 
 
-- Get studylocation id (not entity id)
-- Load them into a temp table
SELECT DISTINCT observation.feature_feature_id as studylocation_entity_id,result.value AS studylocation_id 
INTO TEMP_STUDYLOCATION_IDS_DATA FROM observation, lut_property_type, ex_ultimate_parent_lookup, observation_results, result
where observation.feature_feature_id = ex_ultimate_parent_lookup.ultimate AND observation.property_property_type_id = lut_property_type.property_type_id AND lut_property_type.name = 'Identifier'
AND observation.observation_id = observation_results.observation_observation_id AND observation_results.results_result_id = result.result_id and result.element = 'Value';

-- Update studylocation id
UPDATE EXT_SAMPLING_UNIT SET studylocation_id = trim(both '"' from (SELECT studylocation_id from TEMP_STUDYLOCATION_IDS_DATA where EXT_SAMPLING_UNIT.studylocation_entity_id = TEMP_STUDYLOCATION_IDS_DATA.studylocation_entity_id));

-- Update original study location code
UPDATE EXT_SAMPLING_UNIT SET orginal_site_code = trim (both '"' from substring(studylocation_id, aekos_last_post(studylocation_id, '/') + 1));
	
--Drop temp_studylocation_ids table
DROP TABLE IF EXISTS TEMP_STUDYLOCATION_IDS_DATA;


--Get location of studylocation
SELECT DISTINCT observation.feature_feature_id as studylocation_entity_id,result.element, result.value 
INTO TEMP_STUDYLOCATION_LOCATION_DATA FROM observation, lut_property_type, ex_ultimate_parent_lookup, observation_results, result
where observation.feature_feature_id = ex_ultimate_parent_lookup.ultimate AND observation.property_property_type_id = lut_property_type.property_type_id AND lut_property_type.name = 'Location'
AND observation.observation_id = observation_results.observation_observation_id AND observation_results.results_result_id = result.result_id AND result.element <> 'Type' ORDER BY observation.feature_feature_id;

--Update Geo Datum field
UPDATE EXT_SAMPLING_UNIT SET geodetic_datum = (SELECT value from TEMP_STUDYLOCATION_LOCATION_DATA where EXT_SAMPLING_UNIT.studylocation_entity_id = TEMP_STUDYLOCATION_LOCATION_DATA.studylocation_entity_id AND
TEMP_STUDYLOCATION_LOCATION_DATA.element = 'Datum');
--Update latutude field
UPDATE EXT_SAMPLING_UNIT SET latitude = (SELECT value from TEMP_STUDYLOCATION_LOCATION_DATA where EXT_SAMPLING_UNIT.studylocation_entity_id = TEMP_STUDYLOCATION_LOCATION_DATA.studylocation_entity_id AND
TEMP_STUDYLOCATION_LOCATION_DATA.element = 'Latitude');
-- Update longitude field
UPDATE EXT_SAMPLING_UNIT SET longitude = (SELECT value from TEMP_STUDYLOCATION_LOCATION_DATA where EXT_SAMPLING_UNIT.studylocation_entity_id = TEMP_STUDYLOCATION_LOCATION_DATA.studylocation_entity_id AND
TEMP_STUDYLOCATION_LOCATION_DATA.element = 'Longitude');
--Drop temp_studylocation_ids table
DROP TABLE IF EXISTS TEMP_STUDYLOCATION_LOCATION_DATA;

-- Get sampledArea or samplingUnit size
-- Load them into a temp table
SELECT observation.feature_feature_id as sampledarea_samplingunit_entity_id, ex_ultimate_parent_lookup.ultimate as studylocation_entity_id, result.element, result.value  
INTO TEMP_SAMPLE_AREA_DATA from observation,lut_property_type, ex_ultimate_parent_lookup, observation_results, result  where 
observation.property_property_type_id = lut_property_type.property_type_id and lut_property_type.name = 'Area'
and observation.feature_feature_id = ex_ultimate_parent_lookup.entity and 
observation.observation_id = observation_results.observation_observation_id and 
observation_results.results_result_id = result.result_id ORDER BY observation.feature_feature_id desc;
-- Update the Sampling unit id - 
-- Note: not sure where this data is but for now I am just loading the entity id of the sampledArea or Sampling unit
-- Squid needs to clarify
UPDATE EXT_SAMPLING_UNIT SET sampling_unit_id = (SELECT sampledarea_samplingunit_entity_id FROM TEMP_SAMPLE_AREA_DATA WHERE TEMP_SAMPLE_AREA_DATA.sampledarea_samplingunit_entity_id = EXT_SAMPLING_UNIT.sampledarea_samplingunit_entity_id 
AND TEMP_SAMPLE_AREA_DATA.element = 'Type');
--Update the sampling unit area field
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

