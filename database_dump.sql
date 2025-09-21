--
-- PostgreSQL database dump
--

-- Dumped from database version 15.4
-- Dumped by pg_dump version 15.4

-- Started on 2025-09-21 23:47:04

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
-- TOC entry 2 (class 3079 OID 58514)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 4357 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 229 (class 1259 OID 58479)
-- Name: favorite_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.favorite_locations (
    favorite_location_id integer NOT NULL,
    location_name character varying(100),
    lat double precision,
    lng double precision,
    passenger_id character varying(255)
);


ALTER TABLE public.favorite_locations OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 58478)
-- Name: favorite_locations_favorite_location_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.favorite_locations_favorite_location_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.favorite_locations_favorite_location_id_seq OWNER TO postgres;

--
-- TOC entry 4358 (class 0 OID 0)
-- Dependencies: 228
-- Name: favorite_locations_favorite_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.favorite_locations_favorite_location_id_seq OWNED BY public.favorite_locations.favorite_location_id;

--
-- TOC entry 217 (class 1259 OID 58407)
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    notif_id integer NOT NULL,
    notif_title character varying(30),
    notif_type character varying(100),
    content text,
    notif_date date
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 58406)
-- Name: notifications_notif_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_notif_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_notif_id_seq OWNER TO postgres;

--
-- TOC entry 4359 (class 0 OID 0)
-- Dependencies: 216
-- Name: notifications_notif_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_notif_id_seq OWNED BY public.notifications.notif_id;

--
-- TOC entry 225 (class 1259 OID 58457)
-- Name: passenger_trip; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.passenger_trip (
    request_id integer NOT NULL,
    passenger_id character varying(255) NOT NULL,
    pickup_lat numeric(9,6) NOT NULL,
    pickup_lng numeric(9,6) NOT NULL,
    dropoff_lat numeric(9,6) DEFAULT NULL::numeric,
    dropoff_lng numeric(9,6) DEFAULT NULL::numeric,
    status character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    vehicle_id integer,
    route_id integer
);


ALTER TABLE public.passenger_trip OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 58456)
-- Name: passenger_trip_request_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.passenger_trip_request_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.passenger_trip_request_id_seq OWNER TO postgres;

--
-- TOC entry 4360 (class 0 OID 0)
-- Dependencies: 224
-- Name: passenger_trip_request_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.passenger_trip_request_id_seq OWNED BY public.passenger_trip.request_id;


--
-- TOC entry 223 (class 1259 OID 58440)
-- Name: route_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.route_mapping (
    route_map_id integer NOT NULL,
    from_route_id integer,
    to_route_id integer
);


ALTER TABLE public.route_mapping OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 58439)
-- Name: route_mapping_route_map_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.route_mapping_route_map_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.route_mapping_route_map_id_seq OWNER TO postgres;

--
-- TOC entry 4361 (class 0 OID 0)
-- Dependencies: 222
-- Name: route_mapping_route_map_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.route_mapping_route_map_id_seq OWNED BY public.route_mapping.route_map_id;

--
-- TOC entry 221 (class 1259 OID 58428)
-- Name: routes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.routes (
    route_id integer NOT NULL,
    route_name character varying(30),
    start_lat double precision,
    start_lng double precision,
    start_area numeric(9,6),
    end_lat double precision,
    end_lng double precision,
    end_area numeric(9,6),
    route_geom public.geometry(LineString,4326)
);


ALTER TABLE public.routes OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 58427)
-- Name: routes_route_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.routes_route_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.routes_route_id_seq OWNER TO postgres;

--
-- TOC entry 4362 (class 0 OID 0)
-- Dependencies: 220
-- Name: routes_route_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.routes_route_id_seq OWNED BY public.routes.route_id;


--
-- TOC entry 219 (class 1259 OID 58416)
-- Name: trips; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trips (
    trip_id integer NOT NULL,
    vehicle_id integer NOT NULL,
    start_time timestamp without time zone NOT NULL,
    start_lat double precision NOT NULL,
    start_lng double precision NOT NULL,
    end_time timestamp without time zone,
    end_lat double precision,
    end_lng double precision,
    status character varying(20)
);


ALTER TABLE public.trips OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 58415)
-- Name: trips_trip_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.trips_trip_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.trips_trip_id_seq OWNER TO postgres;

--
-- TOC entry 4363 (class 0 OID 0)
-- Dependencies: 218
-- Name: trips_trip_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.trips_trip_id_seq OWNED BY public.trips.trip_id;

--
-- TOC entry 227 (class 1259 OID 58472)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    full_name character varying(50),
    user_role character varying(20),
    username character varying(50),
    user_pass character varying(50)
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 58471)
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_user_id_seq OWNER TO postgres;

--
-- TOC entry 4364 (class 0 OID 0)
-- Dependencies: 226
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- TOC entry 237 (class 1259 OID 66711)
-- Name: vehicle_assignment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicle_assignment (
    assignment_id integer NOT NULL,
    vehicle_id integer NOT NULL,
    user_id integer NOT NULL,
    assigned_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.vehicle_assignment OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 66710)
-- Name: vehicle_assignment_assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.vehicle_assignment_assignment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.vehicle_assignment_assignment_id_seq OWNER TO postgres;

--
-- TOC entry 4365 (class 0 OID 0)
-- Dependencies: 236
-- Name: vehicle_assignment_assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vehicle_assignment_assignment_id_seq OWNED BY public.vehicle_assignment.assignment_id;


--
-- TOC entry 235 (class 1259 OID 59612)
-- Name: vehicle_geofence_state; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicle_geofence_state (
    vehicle_id integer NOT NULL,
    at_start boolean DEFAULT false,
    at_end boolean DEFAULT false,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.vehicle_geofence_state OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 58401)
-- Name: vehicles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicles (
    vehicle_id integer NOT NULL,
    lat double precision,
    lng double precision,
    last_update timestamp without time zone,
    route_id integer,
    current_location public.geometry(Point,4326)
);


ALTER TABLE public.vehicles OWNER TO postgres;

--
-- TOC entry 4149 (class 2604 OID 58482)
-- Name: favorite_locations favorite_location_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_locations ALTER COLUMN favorite_location_id SET DEFAULT nextval('public.favorite_locations_favorite_location_id_seq'::regclass);


--
-- TOC entry 4140 (class 2604 OID 58410)
-- Name: notifications notif_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN notif_id SET DEFAULT nextval('public.notifications_notif_id_seq'::regclass);


--
-- TOC entry 4144 (class 2604 OID 58460)
-- Name: passenger_trip request_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passenger_trip ALTER COLUMN request_id SET DEFAULT nextval('public.passenger_trip_request_id_seq'::regclass);


--
-- TOC entry 4143 (class 2604 OID 58443)
-- Name: route_mapping route_map_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.route_mapping ALTER COLUMN route_map_id SET DEFAULT nextval('public.route_mapping_route_map_id_seq'::regclass);


--
-- TOC entry 4142 (class 2604 OID 58431)
-- Name: routes route_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.routes ALTER COLUMN route_id SET DEFAULT nextval('public.routes_route_id_seq'::regclass);


--
-- TOC entry 4141 (class 2604 OID 58419)
-- Name: trips trip_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trips ALTER COLUMN trip_id SET DEFAULT nextval('public.trips_trip_id_seq'::regclass);


--
-- TOC entry 4148 (class 2604 OID 58475)
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- TOC entry 4153 (class 2604 OID 66714)
-- Name: vehicle_assignment assignment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle_assignment ALTER COLUMN assignment_id SET DEFAULT nextval('public.vehicle_assignment_assignment_id_seq'::regclass);

--
-- TOC entry 4348 (class 0 OID 58479)
-- Dependencies: 229
-- Data for Name: favorite_locations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.favorite_locations (favorite_location_id, location_name, lat, lng, passenger_id) VALUES (1, 'San Nicolas Street Mataas Na Lupa, Lipa City, Batangas, Philippines', 13.948648555868768, 121.159154786204, 'de81326a-4435-46d6-abfb-5b67e2cd3092');
INSERT INTO public.favorite_locations (favorite_location_id, location_name, lat, lng, passenger_id) VALUES (2, 'Jasmine Street Mataas Na Lupa, Lipa City, Batangas, Philippines', 13.949181672995971, 121.15888012695314, '8d604653-f4de-440c-a29f-bc0d4c53f630');
INSERT INTO public.favorite_locations (favorite_location_id, location_name, lat, lng, passenger_id) VALUES (3, 'Ayala Highway Mataas Na Lupa, Lipa City, Batangas, Philippines', 13.950681062282365, 121.15726650843818, '9d9cb879-ea63-45c8-b20a-ee94f942f6b9');


--
-- TOC entry 4336 (class 0 OID 58407)
-- Dependencies: 217
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.notifications (notif_id, notif_title, notif_type, content, notif_date) VALUES (1, 'New Update', 'info', 'There is a new update available.', '2025-08-12');


--
-- TOC entry 4344 (class 0 OID 58457)
-- Dependencies: 225
-- Data for Name: passenger_trip; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.passenger_trip (request_id, passenger_id, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, status, created_at, vehicle_id, route_id) VALUES (1, 'GUEST-123', 13.950293, 121.157943, NULL, NULL, 'pending', '2025-09-10 22:08:21.773625', NULL, 1);


--
-- TOC entry 4342 (class 0 OID 58440)
-- Dependencies: 223
-- Data for Name: route_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.route_mapping (route_map_id, from_route_id, to_route_id) VALUES (1, 1, 2);
INSERT INTO public.route_mapping (route_map_id, from_route_id, to_route_id) VALUES (2, 2, 1);
