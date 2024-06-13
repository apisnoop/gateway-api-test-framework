begin;
create or replace function load_live_open_api (
  )
returns text AS $$
from string import Template
import json
import time
import datetime
from urllib.request import Request, urlopen, urlretrieve
import urllib
import yaml
import ssl
from pathlib import Path

with open('/openapi.json') as f:
  open_api = json.load(f)

release =  '1.1.0'
release_date = time.mktime(datetime.datetime.now().timetuple())
open_api_url = 'incluster'

sql = Template("""
   WITH open AS (
     SELECT '${open_api}'::jsonb as api_data
     )
       INSERT INTO open_api(
         release,
         release_date,
         endpoint,
         level,
         category,
         path,
         k8s_group,
         k8s_version,
         k8s_kind,
         k8s_action,
         deprecated,
         description,
         spec
       )
   SELECT
     '${release}' as release,
     to_timestamp(${release_date}) as release_date,
     (d.value ->> 'operationId'::text) as endpoint,
     CASE
       WHEN paths.key ~~ '%alpha%' THEN 'alpha'
       WHEN paths.key ~~ '%beta%' THEN 'beta'
       -- these endpoints are beta, but are not marked as such, yet, in the swagger.json
       WHEN (d.value ->> 'operationId'::text) = any('{"getServiceAccountIssuerOpenIDConfiguration", "getServiceAccountIssuerOpenIDKeyset"}') THEN 'beta'
       ELSE 'stable'
     END AS level,
     split_part((cat_tag.value ->> 0), '_'::text, 1) AS category,
     paths.key AS path,
     ((d.value -> 'x-kubernetes-group-version-kind'::text) ->> 'group'::text) AS k8s_group,
     ((d.value -> 'x-kubernetes-group-version-kind'::text) ->> 'version'::text) AS k8s_version,
     ((d.value -> 'x-kubernetes-group-version-kind'::text) ->> 'kind'::text) AS k8s_kind,
     (d.value ->> 'x-kubernetes-action'::text) AS k8s_action,
     CASE
       WHEN (lower((d.value ->> 'description'::text)) ~~ '%deprecated%'::text) THEN true
       ELSE false
     END AS deprecated,
                 (d.value ->> 'description'::text) AS description,
                 '${open_api_url}' as spec
     FROM
         open
          , jsonb_each((open.api_data -> 'paths'::text)) paths(key, value)
          , jsonb_each(paths.value) d(key, value)
          , jsonb_array_elements((d.value -> 'tags'::text)) cat_tag(value)
    ORDER BY paths.key;
              """).substitute(release = release,
                              release_date = str(release_date),
                              open_api = json.dumps(open_api).replace("'","''"),
                              open_api_url = open_api_url)
try:
  plpy.execute((sql))
  return "{} open api is loaded".format(release)
except Exception as e:
  return "an error occurred: " + str(e) + "\nrelease: " + release
$$ LANGUAGE plpython3u ;
reset role;

comment on function load_live_open_api is 'loads given release to open_api table from incluster api spec.';

select 'load_live_open_api function defined and commented' as "build log";

select * from load_live_open_api();

commit;
