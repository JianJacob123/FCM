--
-- PostgreSQL database dump
--

-- Dumped from database version 14.18 (Homebrew)
-- Dumped by pg_dump version 14.18 (Homebrew)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: glycel_yvon
--

CREATE TABLE public.notifications (
    notif_id integer NOT NULL,
    notif_title character varying(30),
    notif_type character varying(100),
    content text,
    notif_date date
);


ALTER TABLE public.notifications OWNER TO glycel_yvon;

--
-- Name: notifications_notif_id_seq; Type: SEQUENCE; Schema: public; Owner: glycel_yvon
--

CREATE SEQUENCE public.notifications_notif_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_notif_id_seq OWNER TO glycel_yvon;

--
-- Name: notifications_notif_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: glycel_yvon
--

ALTER SEQUENCE public.notifications_notif_id_seq OWNED BY public.notifications.notif_id;


--
-- Name: passenger_trip; Type: TABLE; Schema: public; Owner: glycel_yvon
--

CREATE TABLE public.passenger_trip (
    request_id integer NOT NULL,
    passenger_id integer NOT NULL,
    pickup_lat numeric(9,6) NOT NULL,
    pickup_lng numeric(9,6) NOT NULL,
    dropoff_lat numeric(9,6) DEFAULT NULL::numeric,
    dropoff_lng numeric(9,6) DEFAULT NULL::numeric,
    status character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    vehicle_id integer
);


ALTER TABLE public.passenger_trip OWNER TO glycel_yvon;

--
-- Name: passenger_trip_request_id_seq; Type: SEQUENCE; Schema: public; Owner: glycel_yvon
--

CREATE SEQUENCE public.passenger_trip_request_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.passenger_trip_request_id_seq OWNER TO glycel_yvon;

--
-- Name: passenger_trip_request_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: glycel_yvon
--

ALTER SEQUENCE public.passenger_trip_request_id_seq OWNED BY public.passenger_trip.request_id;


--
-- Name: route_mapping; Type: TABLE; Schema: public; Owner: glycel_yvon
--

CREATE TABLE public.route_mapping (
    route_map_id integer NOT NULL,
    from_route_id integer,
    to_route_id integer
);


ALTER TABLE public.route_mapping OWNER TO glycel_yvon;

--
-- Name: route_mapping_route_map_id_seq; Type: SEQUENCE; Schema: public; Owner: glycel_yvon
--

CREATE SEQUENCE public.route_mapping_route_map_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.route_mapping_route_map_id_seq OWNER TO glycel_yvon;

--
-- Name: route_mapping_route_map_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: glycel_yvon
--

ALTER SEQUENCE public.route_mapping_route_map_id_seq OWNED BY public.route_mapping.route_map_id;


--
-- Name: routes; Type: TABLE; Schema: public; Owner: glycel_yvon
--

CREATE TABLE public.routes (
    route_id integer NOT NULL,
    route_name character varying(30),
    start_lat numeric(9,6),
    start_lng numeric(9,6),
    start_radius integer,
    end_lat numeric(9,6),
    end_lng numeric(9,6),
    end_radius integer
);


ALTER TABLE public.routes OWNER TO glycel_yvon;

--
-- Name: routes_route_id_seq; Type: SEQUENCE; Schema: public; Owner: glycel_yvon
--

CREATE SEQUENCE public.routes_route_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.routes_route_id_seq OWNER TO glycel_yvon;

--
-- Name: routes_route_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: glycel_yvon
--

ALTER SEQUENCE public.routes_route_id_seq OWNED BY public.routes.route_id;


--
-- Name: schedules; Type: TABLE; Schema: public; Owner: glycel_yvon
--

CREATE TABLE public.schedules (
    id integer NOT NULL,
    schedule_date date NOT NULL,
    time_start time without time zone,
    vehicle_id integer,
    status text NOT NULL,
    reason text,
    CONSTRAINT schedules_status_check CHECK ((status = ANY (ARRAY['Active'::text, 'Sick'::text, 'Coding Unit'::text, 'No Schedule'::text, 'Other Reason'::text])))
);


ALTER TABLE public.schedules OWNER TO glycel_yvon;

--
-- Name: schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: glycel_yvon
--

CREATE SEQUENCE public.schedules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.schedules_id_seq OWNER TO glycel_yvon;

--
-- Name: schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: glycel_yvon
--

ALTER SEQUENCE public.schedules_id_seq OWNED BY public.schedules.id;


--
-- Name: trips; Type: TABLE; Schema: public; Owner: glycel_yvon
--

CREATE TABLE public.trips (
    trip_id integer NOT NULL,
    vehicle_id integer NOT NULL,
    start_time timestamp without time zone NOT NULL,
    start_lat numeric(9,6) NOT NULL,
    start_lng numeric(9,6) NOT NULL,
    end_time timestamp without time zone,
    end_lat numeric(9,6),
    end_lng numeric(9,6),
    status character varying(20)
);


ALTER TABLE public.trips OWNER TO glycel_yvon;

--
-- Name: trips_trip_id_seq; Type: SEQUENCE; Schema: public; Owner: glycel_yvon
--

CREATE SEQUENCE public.trips_trip_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.trips_trip_id_seq OWNER TO glycel_yvon;

--
-- Name: trips_trip_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: glycel_yvon
--

ALTER SEQUENCE public.trips_trip_id_seq OWNED BY public.trips.trip_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: glycel_yvon
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    full_name character varying(50) NOT NULL,
    user_role character varying(20) NOT NULL,
    username character varying(50) NOT NULL,
    user_pass character varying(50) NOT NULL,
    active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.users OWNER TO glycel_yvon;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: glycel_yvon
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_user_id_seq OWNER TO glycel_yvon;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: glycel_yvon
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: vehicle_assignment; Type: TABLE; Schema: public; Owner: glycel_yvon
--

CREATE TABLE public.vehicle_assignment (
    assignment_id integer NOT NULL,
    vehicle_id integer NOT NULL,
    user_id integer,
    assigned_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.vehicle_assignment OWNER TO glycel_yvon;

--
-- Name: vehicle_assignment_assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: glycel_yvon
--

CREATE SEQUENCE public.vehicle_assignment_assignment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.vehicle_assignment_assignment_id_seq OWNER TO glycel_yvon;

--
-- Name: vehicle_assignment_assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: glycel_yvon
--

ALTER SEQUENCE public.vehicle_assignment_assignment_id_seq OWNED BY public.vehicle_assignment.assignment_id;


--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: glycel_yvon
--

CREATE TABLE public.vehicles (
    vehicle_id integer NOT NULL,
    lat numeric(9,6),
    lng numeric(9,6),
    last_update timestamp without time zone,
    route_id integer
);


ALTER TABLE public.vehicles OWNER TO glycel_yvon;

--
-- Name: notifications notif_id; Type: DEFAULT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.notifications ALTER COLUMN notif_id SET DEFAULT nextval('public.notifications_notif_id_seq'::regclass);


--
-- Name: passenger_trip request_id; Type: DEFAULT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.passenger_trip ALTER COLUMN request_id SET DEFAULT nextval('public.passenger_trip_request_id_seq'::regclass);


--
-- Name: route_mapping route_map_id; Type: DEFAULT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.route_mapping ALTER COLUMN route_map_id SET DEFAULT nextval('public.route_mapping_route_map_id_seq'::regclass);


--
-- Name: routes route_id; Type: DEFAULT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.routes ALTER COLUMN route_id SET DEFAULT nextval('public.routes_route_id_seq'::regclass);


--
-- Name: schedules id; Type: DEFAULT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.schedules ALTER COLUMN id SET DEFAULT nextval('public.schedules_id_seq'::regclass);


--
-- Name: trips trip_id; Type: DEFAULT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.trips ALTER COLUMN trip_id SET DEFAULT nextval('public.trips_trip_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Name: vehicle_assignment assignment_id; Type: DEFAULT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.vehicle_assignment ALTER COLUMN assignment_id SET DEFAULT nextval('public.vehicle_assignment_assignment_id_seq'::regclass);


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: glycel_yvon
--

COPY public.notifications (notif_id, notif_title, notif_type, content, notif_date) FROM stdin;
1	New Update	info	There is a new update available.	2025-08-12
\.


--
-- Data for Name: passenger_trip; Type: TABLE DATA; Schema: public; Owner: glycel_yvon
--

COPY public.passenger_trip (request_id, passenger_id, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, status, created_at, vehicle_id) FROM stdin;
\.


--
-- Data for Name: route_mapping; Type: TABLE DATA; Schema: public; Owner: glycel_yvon
--

COPY public.route_mapping (route_map_id, from_route_id, to_route_id) FROM stdin;
1	1	2
2	2	1
\.


--
-- Data for Name: routes; Type: TABLE DATA; Schema: public; Owner: glycel_yvon
--

COPY public.routes (route_id, route_name, start_lat, start_lng, start_radius, end_lat, end_lng, end_radius) FROM stdin;
1	Lipa -> Bauan	\N	\N	\N	\N	\N	\N
2	Bauan -> Lipa	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: schedules; Type: TABLE DATA; Schema: public; Owner: glycel_yvon
--

COPY public.schedules (id, schedule_date, time_start, vehicle_id, status, reason) FROM stdin;
736	2025-09-21	04:00:00	2	Active	\N
737	2025-09-21	04:15:00	3	Active	\N
\.


--
-- Data for Name: trips; Type: TABLE DATA; Schema: public; Owner: glycel_yvon
--

COPY public.trips (trip_id, vehicle_id, start_time, start_lat, start_lng, end_time, end_lat, end_lng, status) FROM stdin;
1	1	2025-08-13 21:38:57.22236	14.599500	120.984200	\N	\N	\N	active
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: glycel_yvon
--

COPY public.users (user_id, full_name, user_role, username, user_pass, active, created_at, updated_at) FROM stdin;
1	John Doe	Driver	john_doe	password123	t	2025-09-21 21:29:48.757	2025-09-21 21:29:48.757
2	Jane Smith	Conductor	jane_smith	password123	t	2025-09-21 21:29:48.757	2025-09-21 21:29:48.757
3	Mike Johnson	Driver	mike_johnson	password123	f	2025-09-21 21:29:48.757	2025-09-21 21:29:48.757
4	Sarah Wilson	Conductor	sarah_wilson	password123	t	2025-09-21 21:29:48.757	2025-09-21 21:29:48.757
5	Admin User	Admin	admin_user	password123	t	2025-09-21 21:29:48.757	2025-09-21 21:29:48.757
\.


--
-- Data for Name: vehicle_assignment; Type: TABLE DATA; Schema: public; Owner: glycel_yvon
--

COPY public.vehicle_assignment (assignment_id, vehicle_id, user_id, assigned_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: vehicles; Type: TABLE DATA; Schema: public; Owner: glycel_yvon
--

COPY public.vehicles (vehicle_id, lat, lng, last_update, route_id) FROM stdin;
1	14.599500	120.984200	\N	\N
2	14.603500	120.987600	\N	\N
3	\N	\N	\N	\N
4	\N	\N	\N	\N
5	\N	\N	\N	\N
6	\N	\N	\N	\N
7	\N	\N	\N	\N
8	\N	\N	\N	\N
9	\N	\N	\N	\N
10	\N	\N	\N	\N
11	\N	\N	\N	\N
12	\N	\N	\N	\N
13	\N	\N	\N	\N
14	\N	\N	\N	\N
15	\N	\N	\N	\N
\.


--
-- Name: notifications_notif_id_seq; Type: SEQUENCE SET; Schema: public; Owner: glycel_yvon
--

SELECT pg_catalog.setval('public.notifications_notif_id_seq', 1, true);


--
-- Name: passenger_trip_request_id_seq; Type: SEQUENCE SET; Schema: public; Owner: glycel_yvon
--

SELECT pg_catalog.setval('public.passenger_trip_request_id_seq', 1, false);


--
-- Name: route_mapping_route_map_id_seq; Type: SEQUENCE SET; Schema: public; Owner: glycel_yvon
--

SELECT pg_catalog.setval('public.route_mapping_route_map_id_seq', 2, true);


--
-- Name: routes_route_id_seq; Type: SEQUENCE SET; Schema: public; Owner: glycel_yvon
--

SELECT pg_catalog.setval('public.routes_route_id_seq', 2, true);


--
-- Name: schedules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: glycel_yvon
--

SELECT pg_catalog.setval('public.schedules_id_seq', 737, true);


--
-- Name: trips_trip_id_seq; Type: SEQUENCE SET; Schema: public; Owner: glycel_yvon
--

SELECT pg_catalog.setval('public.trips_trip_id_seq', 1, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: glycel_yvon
--

SELECT pg_catalog.setval('public.users_user_id_seq', 5, true);


--
-- Name: vehicle_assignment_assignment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: glycel_yvon
--

SELECT pg_catalog.setval('public.vehicle_assignment_assignment_id_seq', 1, false);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notif_id);


--
-- Name: passenger_trip passenger_trip_pkey; Type: CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.passenger_trip
    ADD CONSTRAINT passenger_trip_pkey PRIMARY KEY (request_id);


--
-- Name: route_mapping route_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.route_mapping
    ADD CONSTRAINT route_mapping_pkey PRIMARY KEY (route_map_id);


--
-- Name: routes routes_pkey; Type: CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.routes
    ADD CONSTRAINT routes_pkey PRIMARY KEY (route_id);


--
-- Name: schedules schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.schedules
    ADD CONSTRAINT schedules_pkey PRIMARY KEY (id);


--
-- Name: trips trips_pkey; Type: CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_pkey PRIMARY KEY (trip_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: vehicle_assignment vehicle_assignment_pkey; Type: CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.vehicle_assignment
    ADD CONSTRAINT vehicle_assignment_pkey PRIMARY KEY (assignment_id);


--
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (vehicle_id);


--
-- Name: idx_schedules_date; Type: INDEX; Schema: public; Owner: glycel_yvon
--

CREATE INDEX idx_schedules_date ON public.schedules USING btree (schedule_date);


--
-- Name: idx_schedules_date_time; Type: INDEX; Schema: public; Owner: glycel_yvon
--

CREATE INDEX idx_schedules_date_time ON public.schedules USING btree (schedule_date, time_start);


--
-- Name: passenger_trip passenger_trip_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.passenger_trip
    ADD CONSTRAINT passenger_trip_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(vehicle_id);


--
-- Name: route_mapping route_mapping_from_route_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.route_mapping
    ADD CONSTRAINT route_mapping_from_route_id_fkey FOREIGN KEY (from_route_id) REFERENCES public.routes(route_id);


--
-- Name: route_mapping route_mapping_to_route_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.route_mapping
    ADD CONSTRAINT route_mapping_to_route_id_fkey FOREIGN KEY (to_route_id) REFERENCES public.routes(route_id);


--
-- Name: schedules schedules_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.schedules
    ADD CONSTRAINT schedules_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(vehicle_id) ON DELETE SET NULL;


--
-- Name: trips trips_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(vehicle_id);


--
-- Name: vehicle_assignment vehicle_assignment_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.vehicle_assignment
    ADD CONSTRAINT vehicle_assignment_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: vehicles vehicles_route_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: glycel_yvon
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_route_id_fkey FOREIGN KEY (route_id) REFERENCES public.routes(route_id);


--
-- PostgreSQL database dump complete
--

