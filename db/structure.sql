--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: environments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE environments (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    repository_id integer NOT NULL,
    in_channel boolean DEFAULT false NOT NULL,
    aliases text[] DEFAULT '{}'::text[],
    default_ref character varying
);


--
-- Name: environments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE environments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: environments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE environments_id_seq OWNED BY environments.id;


--
-- Name: github_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE github_accounts (
    user_id integer,
    id integer NOT NULL,
    login character varying NOT NULL,
    token character varying NOT NULL
);


--
-- Name: locks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE locks (
    id integer NOT NULL,
    message character varying,
    active boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    environment_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: locks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE locks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE locks_id_seq OWNED BY locks.id;


--
-- Name: repositories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE repositories (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    default_environment character varying
);


--
-- Name: repositories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE repositories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repositories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE repositories_id_seq OWNED BY repositories.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: slack_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE slack_accounts (
    user_id integer,
    id character varying NOT NULL,
    user_name character varying NOT NULL,
    slack_team_id character varying NOT NULL
);


--
-- Name: slack_teams; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE slack_teams (
    id character varying NOT NULL,
    domain character varying NOT NULL,
    github_organization character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY environments ALTER COLUMN id SET DEFAULT nextval('environments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY locks ALTER COLUMN id SET DEFAULT nextval('locks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY repositories ALTER COLUMN id SET DEFAULT nextval('repositories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: environments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY environments
    ADD CONSTRAINT environments_pkey PRIMARY KEY (id);


--
-- Name: github_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY github_accounts
    ADD CONSTRAINT github_accounts_pkey PRIMARY KEY (id);


--
-- Name: locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY locks
    ADD CONSTRAINT locks_pkey PRIMARY KEY (id);


--
-- Name: repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY repositories
    ADD CONSTRAINT repositories_pkey PRIMARY KEY (id);


--
-- Name: slack_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY slack_accounts
    ADD CONSTRAINT slack_accounts_pkey PRIMARY KEY (id);


--
-- Name: slack_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY slack_teams
    ADD CONSTRAINT slack_teams_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_environments_on_repository_id_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_environments_on_repository_id_and_name ON environments USING btree (repository_id, name);


--
-- Name: index_github_accounts_on_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_github_accounts_on_id ON github_accounts USING btree (id);


--
-- Name: index_locks_on_environment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_locks_on_environment_id ON locks USING btree (environment_id);


--
-- Name: index_slack_accounts_on_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_slack_accounts_on_id ON slack_accounts USING btree (id);


--
-- Name: index_slack_teams_on_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_slack_teams_on_id ON slack_teams USING btree (id);


--
-- Name: locked_environment; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX locked_environment ON locks USING btree (environment_id) WHERE active;


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: fk_rails_31d9175b41; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY locks
    ADD CONSTRAINT fk_rails_31d9175b41 FOREIGN KEY (environment_id) REFERENCES environments(id);


--
-- Name: fk_rails_426f571216; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY locks
    ADD CONSTRAINT fk_rails_426f571216 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_4a418d4e27; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY slack_accounts
    ADD CONSTRAINT fk_rails_4a418d4e27 FOREIGN KEY (slack_team_id) REFERENCES slack_teams(id);


--
-- Name: fk_rails_877068538c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY github_accounts
    ADD CONSTRAINT fk_rails_877068538c FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_a29af68464; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY slack_accounts
    ADD CONSTRAINT fk_rails_a29af68464 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_f7496bfdf1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY environments
    ADD CONSTRAINT fk_rails_f7496bfdf1 FOREIGN KEY (repository_id) REFERENCES repositories(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20160203003153');

INSERT INTO schema_migrations (version) VALUES ('20160203003510');

INSERT INTO schema_migrations (version) VALUES ('20160203113511');

INSERT INTO schema_migrations (version) VALUES ('20160205012702');

INSERT INTO schema_migrations (version) VALUES ('20160205013625');

INSERT INTO schema_migrations (version) VALUES ('20160205060045');

INSERT INTO schema_migrations (version) VALUES ('20160205063654');

INSERT INTO schema_migrations (version) VALUES ('20160209012632');

INSERT INTO schema_migrations (version) VALUES ('20160210071446');

INSERT INTO schema_migrations (version) VALUES ('20160210094548');

INSERT INTO schema_migrations (version) VALUES ('20160211061750');

