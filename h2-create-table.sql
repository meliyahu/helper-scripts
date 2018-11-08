Drop table if exists blah;
 CREATE TABLE blah AS SELECT
-- ## site
'qld_corveg' as surveyId,
'corveg_' || sl.location_id as siteId, -- TODO add aekos URI
'TODO' as samplingUnitId,
slv.site_id as visitId,
-- ## feature of interest
'TODO link back to this table' as featureOfInterestParentId,
'TODO' as featureId,
'organism-assemblage-group' as featureOfInterest, -- TODO should we use yellow book values?
s.name as featureOfInterestQualifier,
s.name as originalFeatureOfInterestQualifier, -- we don't want to change it
s.description as originalFeatureOfInterestQualifierDefinition,
'Vegetation Structural Summary Assessment Method' as protocol,
'TODO' as protocolLink, -- get URL to GitHub
'height' as characteristic,
'min' as characteristicQualifier,
sus.htmin as value,
null as lower,
null as upper,
null as category,
null as description,
'metres' as standard
from r_studylocationvisit as slv
inner join r_studylocation as sl
on sl.location_id = slv.location_id
inner join r_sampleunitstrata as sus
on sus.site_id = slv.site_id
inner join r_strata as s
on sus.strata_id = s.id;

CALL CSVWRITE('/Users/mosheh/eem-data/corveg/corveg-height-min.csv', 'SELECT * FROM blah;',  'charset=UTF-8 fieldSeparator=,')
