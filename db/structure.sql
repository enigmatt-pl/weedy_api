\restrict zYOFD43cpvgxt3squIHYk47who3rhAGUW0YTYCuCO1numpJRtlT4CZHSpNT1k0n

-- Dumped from database version 14.22 (Homebrew)
-- Dumped by pg_dump version 14.22 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid_generate_v7(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.uuid_generate_v7() RETURNS uuid
    LANGUAGE plpgsql
    AS $$
      DECLARE
        v_time timestamp with time zone := clock_timestamp();
        v_giga_ms bigint := floor(extract(epoch from v_time) * 1000);
        v_bytes bytea;
      BEGIN
        v_bytes := decode(lpad(to_hex(v_giga_ms), 12, '0'), 'hex') || gen_random_bytes(10);
        v_bytes := set_byte(v_bytes, 6, (get_byte(v_bytes, 6) & 15) | 112);
        v_bytes := set_byte(v_bytes, 8, (get_byte(v_bytes, 8) & 63) | 128);
        RETURN encode(v_bytes, 'hex')::uuid;
      END
      $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id uuid NOT NULL,
    blob_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    blob_id uuid NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: allegro_integrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.allegro_integrations (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    user_id uuid NOT NULL,
    access_token text,
    refresh_token text,
    expires_at timestamp(6) without time zone,
    client_id character varying,
    client_secret text,
    auth_state character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: dispensaries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dispensaries (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    user_id uuid NOT NULL,
    title character varying NOT NULL,
    description text,
    estimated_price numeric(10,2) DEFAULT 0.0 NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    verification_id character varying,
    platform_product_id character varying,
    image_urls jsonb DEFAULT '[]'::jsonb,
    query_data text,
    market_data jsonb DEFAULT '{}'::jsonb,
    external_product_id character varying,
    category_id character varying,
    reasoning text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: page_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.page_views (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    path character varying,
    referrer character varying,
    user_agent character varying,
    browser_name character varying,
    browser_version character varying,
    os_name character varying,
    os_version character varying,
    language character varying,
    languages character varying,
    timezone character varying,
    timezone_offset_minutes integer,
    screen_width integer,
    screen_height integer,
    screen_color_depth integer,
    device_pixel_ratio double precision,
    viewport_width integer,
    viewport_height integer,
    connection_type character varying,
    connection_effective_type character varying,
    connection_downlink_mbps double precision,
    connection_rtt_ms integer,
    hardware_concurrency integer,
    device_memory_gb double precision,
    max_touch_points integer,
    page_title character varying,
    session_storage_available boolean,
    local_storage_available boolean,
    cookies_enabled boolean,
    do_not_track character varying,
    js_heap_size_mb integer,
    ip_address character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    gpu_vendor character varying,
    gpu_renderer character varying,
    battery_level double precision,
    battery_charging boolean,
    visitor_id character varying,
    screen_orientation character varying,
    storage_quota_mb integer,
    storage_usage_mb integer,
    color_scheme character varying,
    country character varying,
    country_code character varying,
    cpu_architecture character varying,
    device_model character varying,
    platform character varying,
    vendor character varying,
    prefers_reduced_motion boolean,
    prefers_high_contrast boolean,
    prefers_forced_colors boolean,
    is_bot boolean,
    is_in_app_browser boolean,
    pdf_viewer_enabled boolean,
    save_data boolean,
    perf_fcp_ms integer,
    perf_lcp_ms integer,
    perf_ttfb_ms integer,
    perf_dom_load_ms integer,
    perf_page_load_ms integer,
    is_touch_device boolean,
    scroll_depth_pct integer,
    scroll_milestones character varying,
    time_on_page_sec integer,
    click_count integer,
    exit_intent boolean
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v7() NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    first_name character varying,
    last_name character varying,
    avatar_url character varying,
    city character varying,
    postcode character varying,
    province character varying,
    allegro_auth_state character varying,
    accepted_terms_at timestamp(6) without time zone,
    accepted_privacy_at timestamp(6) without time zone,
    legal_version character varying,
    role integer DEFAULT 0,
    approved boolean DEFAULT false,
    credits integer DEFAULT 0 NOT NULL
);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: allegro_integrations allegro_integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allegro_integrations
    ADD CONSTRAINT allegro_integrations_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: dispensaries dispensaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispensaries
    ADD CONSTRAINT dispensaries_pkey PRIMARY KEY (id);


--
-- Name: page_views page_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT page_views_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_allegro_integrations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_allegro_integrations_on_user_id ON public.allegro_integrations USING btree (user_id);


--
-- Name: index_dispensaries_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dispensaries_on_created_at ON public.dispensaries USING btree (created_at);


--
-- Name: index_dispensaries_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dispensaries_on_status ON public.dispensaries USING btree (status);


--
-- Name: index_dispensaries_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dispensaries_on_user_id ON public.dispensaries USING btree (user_id);


--
-- Name: index_dispensaries_on_verification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dispensaries_on_verification_id ON public.dispensaries USING btree (verification_id);


--
-- Name: index_page_views_on_ip_address; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_on_ip_address ON public.page_views USING btree (ip_address);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: dispensaries fk_rails_baa008bfd2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispensaries
    ADD CONSTRAINT fk_rails_baa008bfd2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: allegro_integrations fk_rails_f89f02443d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allegro_integrations
    ADD CONSTRAINT fk_rails_f89f02443d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict zYOFD43cpvgxt3squIHYk47who3rhAGUW0YTYCuCO1numpJRtlT4CZHSpNT1k0n

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260422142905'),
('20260326121502'),
('20260326115531'),
('20260326105819'),
('20260326104658'),
('20260326104234'),
('20260326095022'),
('20260326092751'),
('20260326092543'),
('20260326091635'),
('20260315000000');

