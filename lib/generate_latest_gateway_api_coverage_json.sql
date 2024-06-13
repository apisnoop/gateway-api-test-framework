begin;
create or replace function generate_latest_gateway_api_coverage_json()
returns json as $$
declare latest_release varchar;
begin
select '1.1.0' into latest_release;
return(
select jsonb_pretty(row_to_json(c)::jsonb) from (
    select open_api.release, open_api.release_date, open_api.spec,
        count(distinct ec.endpoint)  as "total endpoints",
        count(distinct ec.endpoint) filter (where ec.tested is true)  as "tested endpoints",
        (select array_agg(source) from (select source from audit_event where release = latest_release group by source) s) as sources,
        (select array_agg(row_to_json(endpoint_coverage)) from endpoint_coverage where release = latest_release and endpoint is not null and endpoint ilike '%gatewaynetworking%') as endpoints,
        (select array_agg(row_to_json(audit_event_test)) from audit_event_test where release = latest_release) as tests
    from open_api
    join endpoint_coverage ec using(release)
    where open_api.release = latest_release
    group by open_api.release, open_api.release_date, open_api.spec) c);
end;
$$ language plpgsql;

commit;

begin;
 \! mkdir -p /tmp/coverage
 \gset
 \set output_file 'resources/coverage/1.1.0.json'
 \t
 \a
 \o :output_file
select * from generate_latest_gateway_api_coverage_json();
 \o
 \a
 \t
commit;
