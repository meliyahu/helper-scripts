
-- Create the base Organism table: EXT_ORGANISM

DROP TABLE IF EXISTS EXT_ORGANISM;

SELECT observation.observation_id, observation.feature_feature_id as featureId, lut_feature_type.name as featureOfInterest, 
lut_feature_qualifier_type.name as featureQualifier, 
lut_original_feature_type.name as orignalFeatureOfInterest,
observation.procedure_procedure_id as protocolLink,
procedure.name as protocol,
lut_property_type.name as property,
lut_property_qualifier_type.name as propertyQualifier 
INTO EXT_ORGANISM   
FROM observation, 
feature, 
lut_feature_type, 
lut_feature_qualifier_type,
lut_original_feature_type,
procedure,
lut_property_type,
lut_property_qualifier_type
WHERE observation.feature_feature_id = feature.feature_id AND 
feature.feature_type_feature_type_id = lut_feature_type.feature_type_id AND 
feature.feature_qualifier_feature_qualifier_type_id = lut_feature_qualifier_type.feature_qualifier_type_id AND
feature.original_feature_type_original_feature_type_id = lut_original_feature_type.original_feature_type_id AND 
(lut_feature_type.name = 'AssemblageOrgGroup' OR 
lut_feature_type.name = 'SpeciesOrgGroup' OR
lut_feature_type.name = 'BioticItem') AND
observation.procedure_procedure_id = procedure.procedure_id AND
observation.property_property_type_id = lut_property_type.property_type_id AND
observation.property_qualifier_property_qualifier_type_id = lut_property_qualifier_type.property_qualifier_type_id;

ALTER TABLE EXT_ORGANISM
 ADD COLUMN id BIGSERIAL PRIMARY KEY,
 ADD COLUMN surveyid VARCHAR,
 ADD COLUMN surveyname VARCHAR,
 ADD COLUMN ultimatefeatureofinterest VARCHAR,
 ADD COLUMN value VARCHAR,
 ADD COLUMN rangelow VARCHAR,
 ADD COLUMN rangehigh VARCHAR,
 ADD COLUMN category VARCHAR,
 ADD COLUMN comment VARCHAR,
 ADD COLUMN standard VARCHAR;
 
 -----------------------------------------------------------------
 -----------------------------------------------------------------
-- Process survey id and survey name
DROP TABLE IF EXISTS TEMP_SURVEY_DATA;

SELECT EXT_ULTIMATE_PARENT_LOOKUP.entity, metadata.persistentsurvey_id, metadata.survey_name 
INTO TEMP_SURVEY_DATA 
FROM
EXT_ULTIMATE_PARENT_LOOKUP,
survey_link,
metadata
WHERE
EXT_ULTIMATE_PARENT_LOOKUP.ultimate_studylocation_entity_id = survey_link.study_location_feature_id AND
survey_link.metadata_survey_id = metadata.survey_id;

UPDATE EXT_ORGANISM SET surveyid = (SELECT persistentsurvey_id FROM TEMP_SURVEY_DATA WHERE EXT_ORGANISM.featureId = TEMP_SURVEY_DATA.entity);
UPDATE EXT_ORGANISM SET surveyname = (SELECT survey_name FROM TEMP_SURVEY_DATA WHERE  EXT_ORGANISM.featureId = TEMP_SURVEY_DATA.entity);  

UPDATE EXT_ORGANISM SET surveyid = trim (both '"' from surveyid);
UPDATE EXT_ORGANISM SET surveyname = trim (both '"' from surveyname);

DROP TABLE IF EXISTS TEMP_SURVEY_DATA;

-----------------------------------------------------------------
-----------------------------------------------------------------
-- Process studylocation
DROP TABLE IF EXISTS TEMP_STUDYLOCATION_LOCATION_DATA;

SELECT DISTINCT EXT_ULTIMATE_PARENT_LOOKUP.entity, result.value AS studylocation_id
INTO TEMP_STUDYLOCATION_LOCATION_DATA 
FROM observation, lut_property_type, EXT_ULTIMATE_PARENT_LOOKUP, observation_results, result
WHERE observation.feature_feature_id = EXT_ULTIMATE_PARENT_LOOKUP.ultimate_studylocation_entity_id AND
observation.property_property_type_id = lut_property_type.property_type_id AND lut_property_type.name = 'Identifier' AND 
observation.observation_id = observation_results.observation_observation_id AND
observation_results.results_result_id = result.result_id AND result.element <> 'Type' 
ORDER BY EXT_ULTIMATE_PARENT_LOOKUP.entity;

UPDATE TEMP_STUDYLOCATION_LOCATION_DATA SET studylocation_id = trim (both '"' from studylocation_id);

UPDATE EXT_ORGANISM SET ultimatefeatureofinterest = (SELECT studylocation_id FROM TEMP_STUDYLOCATION_LOCATION_DATA
WHERE EXT_ORGANISM.featureid = TEMP_STUDYLOCATION_LOCATION_DATA.entity);

DROP TABLE IF EXISTS TEMP_STUDYLOCATION_LOCATION_DATA;

-----------------------------------------------------------------
-----------------------------------------------------------------
-- Process height and other information if any
DROP TABLE IF EXISTS TEMP_ORGANISM_DATA;

SELECT EXT_ORGANISM.observation_id, EXT_ORGANISM.featureid, result.element, result.value 
INTO TEMP_ORGANISM_DATA 
FROM 
EXT_ORGANISM,
observation_results,
result 
WHERE
EXT_ORGANISM.observation_id = observation_results.observation_observation_id AND 
observation_results.results_result_id = result.result_id ORDER BY EXT_ORGANISM.observation_id asc;

UPDATE EXT_ORGANISM SET value = trim(both '"' from (SELECT value FROM TEMP_ORGANISM_DATA
WHERE EXT_ORGANISM.featureid = TEMP_ORGANISM_DATA.featureid AND TEMP_ORGANISM_DATA.element = 'Value'));

UPDATE EXT_ORGANISM SET rangelow = trim(both '"' from (SELECT value FROM TEMP_ORGANISM_DATA
WHERE EXT_ORGANISM.featureid = TEMP_ORGANISM_DATA.featureid AND TEMP_ORGANISM_DATA.element = 'RangeLow'));

UPDATE EXT_ORGANISM SET rangehigh = trim(both '"' from (SELECT value FROM TEMP_ORGANISM_DATA
WHERE EXT_ORGANISM.featureid = TEMP_ORGANISM_DATA.featureid AND TEMP_ORGANISM_DATA.element = 'RangeHigh'));

UPDATE EXT_ORGANISM SET category = trim(both '"' from (SELECT value FROM TEMP_ORGANISM_DATA
WHERE EXT_ORGANISM.featureid = TEMP_ORGANISM_DATA.featureid AND TEMP_ORGANISM_DATA.element = 'Category'));

UPDATE EXT_ORGANISM SET comment = trim(both '"' from (SELECT value FROM TEMP_ORGANISM_DATA
WHERE EXT_ORGANISM.featureid = TEMP_ORGANISM_DATA.featureid AND TEMP_ORGANISM_DATA.element = 'Comment'));

UPDATE EXT_ORGANISM SET standard = trim(both '"' from (SELECT value FROM TEMP_ORGANISM_DATA
WHERE EXT_ORGANISM.featureid = TEMP_ORGANISM_DATA.featureid AND TEMP_ORGANISM_DATA.element = 'Standard'));

DROP TABLE IF EXISTS TEMP_ORGANISM_DATA;
---------------------------------------------------------
---------------------------------------------------------
COMMIT;


  
