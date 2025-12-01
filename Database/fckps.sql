--
-- PostgreSQL database dump
--

\restrict OucAbG1aT9AfYHB0lbgOR1WWa8fk6u7KbLR2sGDAjk9ZgFulJuApBIzigc6dzhE

-- Dumped from database version 14.19 (Homebrew)
-- Dumped by pg_dump version 18.0

-- Started on 2025-11-30 23:53:30 MST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: kaushal
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO kaushal;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 218 (class 1259 OID 725028)
-- Name: Order; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Order" (
    orderid integer NOT NULL,
    userid integer,
    vendorid integer NOT NULL,
    kioskid integer,
    channel character varying(10) NOT NULL,
    placedat timestamp with time zone DEFAULT now() NOT NULL,
    estimatedreadyat timestamp with time zone,
    status character varying(20) NOT NULL,
    totalamount numeric(10,2) NOT NULL,
    paymentstatus character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    CONSTRAINT "Order_channel_check" CHECK (((channel)::text = ANY ((ARRAY['WEB'::character varying, 'APP'::character varying, 'KIOSK'::character varying])::text[]))),
    CONSTRAINT "Order_status_check" CHECK (((status)::text = ANY ((ARRAY['RECEIVED'::character varying, 'PREPARING'::character varying, 'READY'::character varying, 'PICKED_UP'::character varying, 'CANCELLED'::character varying])::text[])))
);


ALTER TABLE public."Order" OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 725027)
-- Name: Order_orderid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Order_orderid_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Order_orderid_seq" OWNER TO postgres;

--
-- TOC entry 3884 (class 0 OID 0)
-- Dependencies: 217
-- Name: Order_orderid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Order_orderid_seq" OWNED BY public."Order".orderid;


--
-- TOC entry 210 (class 1259 OID 724981)
-- Name: User; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."User" (
    userid integer NOT NULL,
    name character varying(80) NOT NULL,
    email character varying(120),
    phone character varying(20),
    passwordhash character varying(200),
    createdat timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public."User" OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 724980)
-- Name: User_userid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."User_userid_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."User_userid_seq" OWNER TO postgres;

--
-- TOC entry 3885 (class 0 OID 0)
-- Dependencies: 209
-- Name: User_userid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."User_userid_seq" OWNED BY public."User".userid;


--
-- TOC entry 216 (class 1259 OID 725018)
-- Name: kiosk; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.kiosk (
    kioskid integer NOT NULL,
    code character varying(50) NOT NULL,
    location character varying(120) NOT NULL,
    isactive boolean DEFAULT true NOT NULL
);


ALTER TABLE public.kiosk OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 725017)
-- Name: kiosk_kioskid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.kiosk_kioskid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kiosk_kioskid_seq OWNER TO postgres;

--
-- TOC entry 3886 (class 0 OID 0)
-- Dependencies: 215
-- Name: kiosk_kioskid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.kiosk_kioskid_seq OWNED BY public.kiosk.kioskid;


--
-- TOC entry 214 (class 1259 OID 725001)
-- Name: menuitem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.menuitem (
    itemid integer NOT NULL,
    vendorid integer NOT NULL,
    name character varying(120) NOT NULL,
    description text,
    price numeric(10,2) NOT NULL,
    isavailable boolean DEFAULT true NOT NULL,
    category character varying(50)
);


ALTER TABLE public.menuitem OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 725000)
-- Name: menuitem_itemid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.menuitem_itemid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.menuitem_itemid_seq OWNER TO postgres;

--
-- TOC entry 3887 (class 0 OID 0)
-- Dependencies: 213
-- Name: menuitem_itemid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menuitem_itemid_seq OWNED BY public.menuitem.itemid;


--
-- TOC entry 219 (class 1259 OID 725053)
-- Name: orderitem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orderitem (
    orderid integer NOT NULL,
    itemid integer NOT NULL,
    quantity integer NOT NULL,
    unitprice numeric(10,2) NOT NULL,
    customizations text,
    CONSTRAINT orderitem_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE public.orderitem OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 725088)
-- Name: orderstatushistory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orderstatushistory (
    historyid integer NOT NULL,
    orderid integer,
    oldstatus character varying(20),
    newstatus character varying(20) NOT NULL,
    changedat timestamp with time zone DEFAULT now() NOT NULL,
    changedby character varying(20) NOT NULL,
    CONSTRAINT orderstatushistory_changedby_check CHECK (((changedby)::text = ANY ((ARRAY['SYSTEM'::character varying, 'VENDOR'::character varying, 'ADMIN'::character varying])::text[]))),
    CONSTRAINT orderstatushistory_newstatus_check CHECK (((newstatus)::text = ANY ((ARRAY['RECEIVED'::character varying, 'PREPARING'::character varying, 'READY'::character varying, 'PICKED_UP'::character varying, 'CANCELLED'::character varying])::text[])))
);


ALTER TABLE public.orderstatushistory OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 725087)
-- Name: orderstatushistory_historyid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orderstatushistory_historyid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.orderstatushistory_historyid_seq OWNER TO postgres;

--
-- TOC entry 3888 (class 0 OID 0)
-- Dependencies: 222
-- Name: orderstatushistory_historyid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orderstatushistory_historyid_seq OWNED BY public.orderstatushistory.historyid;


--
-- TOC entry 221 (class 1259 OID 725072)
-- Name: payment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment (
    paymentid integer NOT NULL,
    orderid integer,
    method character varying(20) NOT NULL,
    amount numeric(10,2) NOT NULL,
    processorref character varying(100),
    status character varying(20) NOT NULL,
    paidat timestamp with time zone,
    CONSTRAINT payment_method_check CHECK (((method)::text = ANY ((ARRAY['CARD'::character varying, 'WALLET'::character varying, 'CONTACTLESS'::character varying])::text[]))),
    CONSTRAINT payment_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'SUCCEEDED'::character varying, 'FAILED'::character varying, 'REFUNDED'::character varying])::text[])))
);


ALTER TABLE public.payment OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 725071)
-- Name: payment_paymentid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_paymentid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_paymentid_seq OWNER TO postgres;

--
-- TOC entry 3889 (class 0 OID 0)
-- Dependencies: 220
-- Name: payment_paymentid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_paymentid_seq OWNED BY public.payment.paymentid;


--
-- TOC entry 212 (class 1259 OID 724991)
-- Name: vendor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vendor (
    vendorid integer NOT NULL,
    name character varying(120) NOT NULL,
    category character varying(50) NOT NULL,
    isopen boolean DEFAULT true NOT NULL,
    avgprepminutes integer
);


ALTER TABLE public.vendor OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 724990)
-- Name: vendor_vendorid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.vendor_vendorid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vendor_vendorid_seq OWNER TO postgres;

--
-- TOC entry 3890 (class 0 OID 0)
-- Dependencies: 211
-- Name: vendor_vendorid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vendor_vendorid_seq OWNED BY public.vendor.vendorid;


--
-- TOC entry 3677 (class 2604 OID 725031)
-- Name: Order orderid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order" ALTER COLUMN orderid SET DEFAULT nextval('public."Order_orderid_seq"'::regclass);


--
-- TOC entry 3669 (class 2604 OID 724984)
-- Name: User userid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User" ALTER COLUMN userid SET DEFAULT nextval('public."User_userid_seq"'::regclass);


--
-- TOC entry 3675 (class 2604 OID 725021)
-- Name: kiosk kioskid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kiosk ALTER COLUMN kioskid SET DEFAULT nextval('public.kiosk_kioskid_seq'::regclass);


--
-- TOC entry 3673 (class 2604 OID 725004)
-- Name: menuitem itemid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menuitem ALTER COLUMN itemid SET DEFAULT nextval('public.menuitem_itemid_seq'::regclass);


--
-- TOC entry 3681 (class 2604 OID 725091)
-- Name: orderstatushistory historyid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orderstatushistory ALTER COLUMN historyid SET DEFAULT nextval('public.orderstatushistory_historyid_seq'::regclass);


--
-- TOC entry 3680 (class 2604 OID 725075)
-- Name: payment paymentid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment ALTER COLUMN paymentid SET DEFAULT nextval('public.payment_paymentid_seq'::regclass);


--
-- TOC entry 3671 (class 2604 OID 724994)
-- Name: vendor vendorid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor ALTER COLUMN vendorid SET DEFAULT nextval('public.vendor_vendorid_seq'::regclass);


--
-- TOC entry 3872 (class 0 OID 725028)
-- Dependencies: 218
-- Data for Name: Order; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Order" (orderid, userid, vendorid, kioskid, channel, placedat, estimatedreadyat, status, totalamount, paymentstatus) FROM stdin;
2	2	2	\N	WEB	2025-11-09 20:39:35.885666-07	\N	RECEIVED	5.99	PENDING
3	2	2	\N	WEB	2025-11-09 20:43:28.852399-07	\N	RECEIVED	5.99	PENDING
4	2	2	\N	WEB	2025-11-09 20:45:34.254707-07	\N	RECEIVED	5.99	PENDING
1	1	1	1	KIOSK	2025-11-09 20:22:28.420093-07	\N	READY	12.48	PENDING
\.


--
-- TOC entry 3864 (class 0 OID 724981)
-- Dependencies: 210
-- Data for Name: User; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."User" (userid, name, email, phone, passwordhash, createdat) FROM stdin;
1	Ava Patel	ava@example.com	555-1111	hash1	2025-11-09 20:22:28.420093-07
2	Jake Chen	jake@example.com	555-2222	hash2	2025-11-09 20:22:28.420093-07
\.


--
-- TOC entry 3870 (class 0 OID 725018)
-- Dependencies: 216
-- Data for Name: kiosk; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.kiosk (kioskid, code, location, isactive) FROM stdin;
1	KS1	North Entrance	t
2	KS2	Center Court	t
\.


--
-- TOC entry 3868 (class 0 OID 725001)
-- Dependencies: 214
-- Data for Name: menuitem; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.menuitem (itemid, vendorid, name, description, price, isavailable, category) FROM stdin;
1	1	Cheeseburger	Juicy beef patty with cheese	8.99	t	Main
3	2	Mango Smoothie	Fresh mango blended smoothie	5.99	t	Drinks
4	2	Strawberry Smoothie	Fresh strawberry blend	6.49	t	Drinks
5	2	Green Tea	Organic matcha tea	3.99	t	Drinks
6	2	Protein Shake	High protein vanilla shake	7.49	t	Drinks
2	1	Fries	Crispy golden fries	3.49	f	Snacks
\.


--
-- TOC entry 3873 (class 0 OID 725053)
-- Dependencies: 219
-- Data for Name: orderitem; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orderitem (orderid, itemid, quantity, unitprice, customizations) FROM stdin;
1	1	1	8.99	\N
1	2	1	3.49	\N
\.


--
-- TOC entry 3877 (class 0 OID 725088)
-- Dependencies: 223
-- Data for Name: orderstatushistory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orderstatushistory (historyid, orderid, oldstatus, newstatus, changedat, changedby) FROM stdin;
\.


--
-- TOC entry 3875 (class 0 OID 725072)
-- Dependencies: 221
-- Data for Name: payment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payment (paymentid, orderid, method, amount, processorref, status, paidat) FROM stdin;
\.


--
-- TOC entry 3866 (class 0 OID 724991)
-- Dependencies: 212
-- Data for Name: vendor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vendor (vendorid, name, category, isopen, avgprepminutes) FROM stdin;
1	Burger Hub	Main	t	10
2	Smoothie Spot	Drinks	t	5
\.


--
-- TOC entry 3891 (class 0 OID 0)
-- Dependencies: 217
-- Name: Order_orderid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Order_orderid_seq"', 4, true);


--
-- TOC entry 3892 (class 0 OID 0)
-- Dependencies: 209
-- Name: User_userid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."User_userid_seq"', 2, true);


--
-- TOC entry 3893 (class 0 OID 0)
-- Dependencies: 215
-- Name: kiosk_kioskid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.kiosk_kioskid_seq', 2, true);


--
-- TOC entry 3894 (class 0 OID 0)
-- Dependencies: 213
-- Name: menuitem_itemid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.menuitem_itemid_seq', 6, true);


--
-- TOC entry 3895 (class 0 OID 0)
-- Dependencies: 222
-- Name: orderstatushistory_historyid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orderstatushistory_historyid_seq', 1, false);


--
-- TOC entry 3896 (class 0 OID 0)
-- Dependencies: 220
-- Name: payment_paymentid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_paymentid_seq', 1, false);


--
-- TOC entry 3897 (class 0 OID 0)
-- Dependencies: 211
-- Name: vendor_vendorid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vendor_vendorid_seq', 2, true);


--
-- TOC entry 3707 (class 2606 OID 725037)
-- Name: Order Order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_pkey" PRIMARY KEY (orderid);


--
-- TOC entry 3691 (class 2606 OID 724989)
-- Name: User User_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_email_key" UNIQUE (email);


--
-- TOC entry 3693 (class 2606 OID 724987)
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (userid);


--
-- TOC entry 3703 (class 2606 OID 725026)
-- Name: kiosk kiosk_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kiosk
    ADD CONSTRAINT kiosk_code_key UNIQUE (code);


--
-- TOC entry 3705 (class 2606 OID 725024)
-- Name: kiosk kiosk_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kiosk
    ADD CONSTRAINT kiosk_pkey PRIMARY KEY (kioskid);


--
-- TOC entry 3699 (class 2606 OID 725009)
-- Name: menuitem menuitem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menuitem
    ADD CONSTRAINT menuitem_pkey PRIMARY KEY (itemid);


--
-- TOC entry 3701 (class 2606 OID 725011)
-- Name: menuitem menuitem_vendorid_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menuitem
    ADD CONSTRAINT menuitem_vendorid_name_key UNIQUE (vendorid, name);


--
-- TOC entry 3709 (class 2606 OID 725060)
-- Name: orderitem orderitem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orderitem
    ADD CONSTRAINT orderitem_pkey PRIMARY KEY (orderid, itemid);


--
-- TOC entry 3715 (class 2606 OID 725096)
-- Name: orderstatushistory orderstatushistory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orderstatushistory
    ADD CONSTRAINT orderstatushistory_pkey PRIMARY KEY (historyid);


--
-- TOC entry 3711 (class 2606 OID 725081)
-- Name: payment payment_orderid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_orderid_key UNIQUE (orderid);


--
-- TOC entry 3713 (class 2606 OID 725079)
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (paymentid);


--
-- TOC entry 3695 (class 2606 OID 724999)
-- Name: vendor vendor_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor
    ADD CONSTRAINT vendor_name_key UNIQUE (name);


--
-- TOC entry 3697 (class 2606 OID 724997)
-- Name: vendor vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor
    ADD CONSTRAINT vendor_pkey PRIMARY KEY (vendorid);


--
-- TOC entry 3717 (class 2606 OID 725048)
-- Name: Order Order_kioskid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_kioskid_fkey" FOREIGN KEY (kioskid) REFERENCES public.kiosk(kioskid);


--
-- TOC entry 3718 (class 2606 OID 725038)
-- Name: Order Order_userid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_userid_fkey" FOREIGN KEY (userid) REFERENCES public."User"(userid);


--
-- TOC entry 3719 (class 2606 OID 725043)
-- Name: Order Order_vendorid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_vendorid_fkey" FOREIGN KEY (vendorid) REFERENCES public.vendor(vendorid);


--
-- TOC entry 3716 (class 2606 OID 725012)
-- Name: menuitem menuitem_vendorid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menuitem
    ADD CONSTRAINT menuitem_vendorid_fkey FOREIGN KEY (vendorid) REFERENCES public.vendor(vendorid);


--
-- TOC entry 3720 (class 2606 OID 725066)
-- Name: orderitem orderitem_itemid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orderitem
    ADD CONSTRAINT orderitem_itemid_fkey FOREIGN KEY (itemid) REFERENCES public.menuitem(itemid);


--
-- TOC entry 3721 (class 2606 OID 725061)
-- Name: orderitem orderitem_orderid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orderitem
    ADD CONSTRAINT orderitem_orderid_fkey FOREIGN KEY (orderid) REFERENCES public."Order"(orderid);


--
-- TOC entry 3723 (class 2606 OID 725097)
-- Name: orderstatushistory orderstatushistory_orderid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orderstatushistory
    ADD CONSTRAINT orderstatushistory_orderid_fkey FOREIGN KEY (orderid) REFERENCES public."Order"(orderid);


--
-- TOC entry 3722 (class 2606 OID 725082)
-- Name: payment payment_orderid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_orderid_fkey FOREIGN KEY (orderid) REFERENCES public."Order"(orderid);


--
-- TOC entry 3883 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: kaushal
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2025-11-30 23:53:30 MST

--
-- PostgreSQL database dump complete
--

\unrestrict OucAbG1aT9AfYHB0lbgOR1WWa8fk6u7KbLR2sGDAjk9ZgFulJuApBIzigc6dzhE

