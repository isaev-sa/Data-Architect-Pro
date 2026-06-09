CREATE TABLE IF NOT EXISTS raw_stage_grants.ogr_info_from_dadata (
	id serial4 NOT NULL,
	old_inn varchar(12) NULL,
	old_ogrn varchar(20) NULL,
	inn_dadata varchar(12) NULL,
	ogrn_dadata varchar(20) NULL,
	organizations_count int4 NULL,
	dadata_response jsonb NULL,
	status varchar(20) NULL,
	error text NULL,
	record_source varchar(50) NULL,
	load_datetime timestamp NULL,
	CONSTRAINT ogr_info_from_dadata_pkey PRIMARY KEY (id)
)