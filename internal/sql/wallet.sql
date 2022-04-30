--
-- PostgreSQL database dump
--

-- Dumped from database version 12.2
-- Dumped by pg_dump version 12.2

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
-- Name: top_up_wallet(bigint, character varying, numeric, integer, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.top_up_wallet(p_user_id bigint, p_phone character varying, p_amount numeric, INOUT p_code integer, INOUT p_message character varying)
    LANGUAGE plpgsql
    AS $$
declare
    d_from_acc     bigint;
    d_to_acc       bigint;
    d_from_balance numeric;
    d_to_balance   numeric;
    d_trans_id     bigint;
    d_identified   bool;
    d_id           bigint;
begin

    select a.id, a.account_balance
    from account a
             inner join client c on c.id = a.client_id
             inner join "user" u on u.id = c.user_id
    where u.id = p_user_id
    into d_from_acc, d_from_balance;

    select a.id, a.account_balance, c.is_identified
    from account a
             inner join client c on c.id = a.client_id
             inner join "user" u on u.id = c.user_id
    where u.phone = p_phone
    into d_to_acc, d_to_balance, d_identified;
    if d_from_acc = d_to_acc then
        p_code = 1;
        p_message = 'The same account';
        return;
    end if;
    if d_from_balance - p_amount < 0 then
        p_code = 1;
        p_message = 'Not enough money';
        return;
    end if;

    if d_to_balance + p_amount > 10000 and d_identified <> true then
        p_code = 1;
        p_message = 'The balance of an unidentified user must not exceed 10 000';
        return;
    end if;

    if d_to_balance + p_amount > 100000 and d_identified then
        p_code = 1;
        p_message = 'The balance of an identified user must not exceed 100 000';
        return;
    end if;
    insert into transaction (account_from, account_to, amount, description, status_id)
    values (d_from_acc, d_to_acc, p_amount, 'TopUp wallet', 1)
    returning id into d_trans_id;
    if d_trans_id <= 0 then
        p_code = 2;
        p_message = 'Error on create transaction';
        rollback;
    end if;
    update account set account_balance = d_from_balance - p_amount where id = d_from_acc returning id into d_id;
    if d_id <= 0 then
        p_code = 2;
        p_message = 'Error on update account balance';
        rollback;
    end if;
    update account set account_balance = d_to_balance + p_amount where id = d_to_acc returning id into d_id;
    if d_id <= 0 then
        p_code = 2;
        p_message = 'Error on update account balance';
        rollback;
    end if;
    insert into record (account_id, operation_id, amount, start_balance, trans_id, description)
    values (d_from_acc, 1, p_amount, d_from_balance, d_trans_id, 'TopUp wallet')
    returning id into d_id;
    if d_id <= 0 then
        p_code = 2;
        p_message = 'Error on insert to record credit';
        rollback;
    end if;

    insert into record (account_id, operation_id, amount, start_balance, trans_id, description)
    values (d_to_acc, 2, p_amount, d_to_balance, d_trans_id, 'TopUp wallet')
    returning id into d_id;
    if d_id <= 0 then
        p_code = 2;
        p_message = 'Error on insert to record credit';
        rollback;
    end if;
    p_code = 0;
    p_message = 'Operation successful';
end;
$$;


ALTER PROCEDURE public.top_up_wallet(p_user_id bigint, p_phone character varying, p_amount numeric, INOUT p_code integer, INOUT p_message character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.account (
    id bigint NOT NULL,
    client_id bigint,
    account_num character varying,
    account_type_id integer,
    account_balance numeric,
    create_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_update timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.account OWNER TO postgres;

--
-- Name: account_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.account_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.account_id_seq OWNER TO postgres;

--
-- Name: account_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.account_id_seq OWNED BY public.account.id;


--
-- Name: account_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.account_type (
    id integer NOT NULL,
    name character varying,
    code character varying,
    description character varying,
    create_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.account_type OWNER TO postgres;

--
-- Name: account_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.account_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.account_type_id_seq OWNER TO postgres;

--
-- Name: account_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.account_type_id_seq OWNED BY public.account_type.id;


--
-- Name: address; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.address (
    id bigint NOT NULL,
    region_id integer NOT NULL,
    district_id integer NOT NULL,
    street character varying,
    house character varying,
    apt character varying,
    create_date character varying
);


ALTER TABLE public.address OWNER TO postgres;

--
-- Name: address_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.address_id_seq OWNER TO postgres;

--
-- Name: address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.address_id_seq OWNED BY public.address.id;


--
-- Name: region; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.region (
    id integer NOT NULL,
    name character varying,
    code character varying,
    create_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.region OWNER TO postgres;

--
-- Name: city_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.city_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.city_id_seq OWNER TO postgres;

--
-- Name: city_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.city_id_seq OWNED BY public.region.id;


--
-- Name: client; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    s_name character varying,
    name character varying,
    patronymic character varying,
    itn character varying,
    birth_date date,
    client_doc_id bigint,
    address_id bigint,
    sex_id integer,
    is_identified boolean DEFAULT false,
    create_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_update timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.client OWNER TO postgres;

--
-- Name: client_doc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client_doc (
    id bigint NOT NULL,
    series character varying NOT NULL,
    number character varying NOT NULL,
    issue_date date NOT NULL,
    expire_date date,
    issued character varying NOT NULL,
    create_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.client_doc OWNER TO postgres;

--
-- Name: client_docs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.client_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.client_docs_id_seq OWNER TO postgres;

--
-- Name: client_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.client_docs_id_seq OWNED BY public.client_doc.id;


--
-- Name: client_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.client_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.client_id_seq OWNER TO postgres;

--
-- Name: client_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.client_id_seq OWNED BY public.client.id;


--
-- Name: district; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.district (
    id integer NOT NULL,
    name character varying,
    code character varying,
    create_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.district OWNER TO postgres;

--
-- Name: district_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.district_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.district_id_seq OWNER TO postgres;

--
-- Name: district_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.district_id_seq OWNED BY public.district.id;


--
-- Name: operation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.operation (
    id integer NOT NULL,
    name character varying,
    code character varying,
    create_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.operation OWNER TO postgres;

--
-- Name: operation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.operation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.operation_id_seq OWNER TO postgres;

--
-- Name: operation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.operation_id_seq OWNED BY public.operation.id;


--
-- Name: record; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.record (
    id bigint NOT NULL,
    account_id bigint,
    operation_id integer,
    amount numeric,
    start_balance numeric,
    trans_id bigint,
    description character varying,
    create_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.record OWNER TO postgres;

--
-- Name: record_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.record_id_seq OWNER TO postgres;

--
-- Name: record_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.record_id_seq OWNED BY public.record.id;


--
-- Name: sex; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sex (
    id integer NOT NULL,
    name character varying,
    code character varying,
    create_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.sex OWNER TO postgres;

--
-- Name: sex_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sex_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sex_id_seq OWNER TO postgres;

--
-- Name: sex_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sex_id_seq OWNED BY public.sex.id;


--
-- Name: trans_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trans_status (
    id integer NOT NULL,
    name character varying,
    code character varying,
    create_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.trans_status OWNER TO postgres;

--
-- Name: trans_status_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.trans_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.trans_status_id_seq OWNER TO postgres;

--
-- Name: trans_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.trans_status_id_seq OWNED BY public.trans_status.id;


--
-- Name: transaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transaction (
    id bigint NOT NULL,
    account_from bigint NOT NULL,
    account_to bigint NOT NULL,
    amount numeric,
    description character varying,
    status_id integer,
    create_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_update timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.transaction OWNER TO postgres;

--
-- Name: transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transaction_id_seq OWNER TO postgres;

--
-- Name: transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transaction_id_seq OWNED BY public.transaction.id;


--
-- Name: user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."user" (
    id bigint NOT NULL,
    phone character varying NOT NULL,
    pin_code_hash character varying,
    is_active boolean DEFAULT true,
    create_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_update timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public."user" OWNER TO postgres;

--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_id_seq OWNER TO postgres;

--
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_id_seq OWNED BY public."user".id;


--
-- Name: account id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account ALTER COLUMN id SET DEFAULT nextval('public.account_id_seq'::regclass);


--
-- Name: account_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_type ALTER COLUMN id SET DEFAULT nextval('public.account_type_id_seq'::regclass);


--
-- Name: address id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.address ALTER COLUMN id SET DEFAULT nextval('public.address_id_seq'::regclass);


--
-- Name: client id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client ALTER COLUMN id SET DEFAULT nextval('public.client_id_seq'::regclass);


--
-- Name: client_doc id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_doc ALTER COLUMN id SET DEFAULT nextval('public.client_docs_id_seq'::regclass);


--
-- Name: district id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.district ALTER COLUMN id SET DEFAULT nextval('public.district_id_seq'::regclass);


--
-- Name: operation id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operation ALTER COLUMN id SET DEFAULT nextval('public.operation_id_seq'::regclass);


--
-- Name: record id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.record ALTER COLUMN id SET DEFAULT nextval('public.record_id_seq'::regclass);


--
-- Name: region id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.region ALTER COLUMN id SET DEFAULT nextval('public.city_id_seq'::regclass);


--
-- Name: sex id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sex ALTER COLUMN id SET DEFAULT nextval('public.sex_id_seq'::regclass);


--
-- Name: trans_status id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trans_status ALTER COLUMN id SET DEFAULT nextval('public.trans_status_id_seq'::regclass);


--
-- Name: transaction id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction ALTER COLUMN id SET DEFAULT nextval('public.transaction_id_seq'::regclass);


--
-- Name: user id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user" ALTER COLUMN id SET DEFAULT nextval('public.user_id_seq'::regclass);


--
-- Data for Name: account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.account (id, client_id, account_num, account_type_id, account_balance, create_date, last_update) FROM stdin;
1	7	841123000000	1	5000	2022-04-30 07:33:33.425641	2022-04-30 07:33:33.425641
2	8	841123154789	1	50000	2022-04-30 07:33:33.425641	2022-04-30 07:33:33.425641
3	9	841127878798	1	30000	2022-04-30 07:33:33.425641	2022-04-30 07:33:33.425641
7	13	000000000001	2	100000	2022-04-30 07:33:33.425641	2022-04-30 07:33:33.425641
6	12	845779956546	1	41400	2022-04-30 07:33:33.425641	2022-04-30 07:33:33.425641
4	10	841178744566	1	59000	2022-04-30 07:33:33.425641	2022-04-30 07:33:33.425641
5	11	841124574126	1	67600	2022-04-30 07:33:33.425641	2022-04-30 07:33:33.425641
\.


--
-- Data for Name: account_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.account_type (id, name, code, description, create_date) FROM stdin;
1	Wallet	WALLET	Wallet account	2022-04-30 06:48:28.997834
2	Agent	AGENT	Agent account	2022-04-30 06:48:28.997834
\.


--
-- Data for Name: address; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.address (id, region_id, district_id, street, house, apt, create_date) FROM stdin;
1	1	2	Н.Махсум	10/2	1	\N
2	2	4	А.Дониш	1	16	\N
3	3	6	Ботробод	110	\N	\N
4	2	5	Айни	115	58	\N
5	1	3	Ломоносов	50	\N	\N
\.


--
-- Data for Name: client; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client (id, user_id, s_name, name, patronymic, itn, birth_date, client_doc_id, address_id, sex_id, is_identified, create_date, last_update) FROM stdin;
7	1	\N	\N	\N	\N	\N	\N	\N	\N	f	2022-04-30 07:11:27.014498	2022-04-30 07:11:27.014498
8	2	Абдуллоев	Акбар	Абдуллоевич	000001565	1983-04-29	1	1	1	t	2022-04-30 07:11:27.014498	2022-04-30 07:11:27.014498
12	6	Гуломова	Файзигул	Ахатовна	008798785	2000-02-08	5	5	2	t	2022-04-30 07:11:27.014498	2022-04-30 07:11:27.014498
9	3	Калонова	Чамила	Расулловна	470000015	1995-04-07	2	2	2	t	2022-04-30 07:11:27.014498	2022-04-30 07:11:27.014498
11	5	Зоиров	Бахтиёр	Шерович	000681565	1996-06-14	4	4	1	t	2022-04-30 07:11:27.014498	2022-04-30 07:11:27.014498
10	4	Файзуллои	Мурод	\N	005801565	1997-03-05	3	3	1	t	2022-04-30 07:11:27.014498	2022-04-30 07:11:27.014498
13	7	\N	\N	\N	\N	\N	\N	\N	\N	f	2022-04-30 07:27:44.202924	2022-04-30 07:27:44.202924
\.


--
-- Data for Name: client_doc; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client_doc (id, series, number, issue_date, expire_date, issued, create_date) FROM stdin;
1	A	56565487	2017-04-06	2027-04-05	ШВКД-2 н.Хисор	2022-04-30 07:19:17.32839
2	A	56562356	2016-06-06	2026-06-05	ШВКД-1 н.Сино ш.Душанбе	2022-04-30 07:19:17.32839
3	A	56568974	2013-10-10	2023-10-09	ШВКД-1 н.И.Сомони ш.Душанбе	2022-04-30 07:19:17.32839
4	A	56561236	2014-07-05	2024-07-04	ШВКД-2 н.Темурмалик ш.Кулоб	2022-04-30 07:19:17.32839
5	A	56568946	2015-11-05	2025-11-04	ШВКД дар н.Вахш	2022-04-30 07:19:17.32839
\.


--
-- Data for Name: district; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.district (id, name, code, create_date) FROM stdin;
1	Sino	SINO	2022-04-30 06:34:48.387856
2	Firdavsi	FIRDAVSI	2022-04-30 06:34:48.387856
3	I.Somoni	I_SOMONI	2022-04-30 06:34:48.387856
4	Shohmansur	SHOHMANSUR	2022-04-30 06:34:48.387856
5	Vakhsh	VAKHSH	2022-04-30 07:23:27.789828
6	Temurmalik	TEMURMALIK	2022-04-30 07:23:27.789828
\.


--
-- Data for Name: operation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.operation (id, name, code, create_date) FROM stdin;
1	Debit	DEBIT	2022-04-30 12:13:47.902254
2	Credit	CREDIT	2022-04-30 12:13:47.902254
\.


--
-- Data for Name: record; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.record (id, account_id, operation_id, amount, start_balance, trans_id, description, create_date) FROM stdin;
1	5	1	200	67200	1	TopUp wallet	2022-04-30 18:15:00.105644
2	6	2	200	40800	1	TopUp wallet	2022-04-30 18:15:00.105644
3	5	1	200	67000	2	TopUp wallet	2022-04-30 18:15:01.259313
4	6	2	200	41000	2	TopUp wallet	2022-04-30 18:15:01.259313
5	5	1	200	66800	3	TopUp wallet	2022-04-30 18:15:01.929313
6	6	2	200	41200	3	TopUp wallet	2022-04-30 18:15:01.929313
7	4	1	200	60000	4	TopUp wallet	2022-04-30 18:39:22.620743
8	5	2	200	66600	4	TopUp wallet	2022-04-30 18:39:22.620743
9	4	1	200	59800	5	TopUp wallet	2022-04-30 18:39:24.848206
10	5	2	200	66800	5	TopUp wallet	2022-04-30 18:39:24.848206
11	4	1	200	59600	6	TopUp wallet	2022-04-30 18:39:25.265926
12	5	2	200	67000	6	TopUp wallet	2022-04-30 18:39:25.265926
13	4	1	200	59400	7	TopUp wallet	2022-04-30 18:39:26.701996
14	5	2	200	67200	7	TopUp wallet	2022-04-30 18:39:26.701996
15	4	1	200	59200	8	TopUp wallet	2022-04-30 18:39:27.34686
16	5	2	200	67400	8	TopUp wallet	2022-04-30 18:39:27.34686
\.


--
-- Data for Name: region; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.region (id, name, code, create_date) FROM stdin;
1	Dushanbe	DUSHANBE	2022-04-30 06:36:17.29566
2	Bokhtar	BOKHTAR	2022-04-30 06:36:17.29566
3	Kulob	KULOB	2022-04-30 06:36:17.29566
\.


--
-- Data for Name: sex; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sex (id, name, code, create_date) FROM stdin;
1	Male	MALE	2022-04-30 06:32:32.680686
2	Female	FEMALE	2022-04-30 06:32:32.680686
\.


--
-- Data for Name: trans_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trans_status (id, name, code, create_date) FROM stdin;
1	Success	SUCCESS	2022-04-30 12:04:55.095349
2	Canceled	CANCELED	2022-04-30 12:04:55.095349
\.


--
-- Data for Name: transaction; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transaction (id, account_from, account_to, amount, description, status_id, create_date, last_update) FROM stdin;
1	5	6	200	TopUp wallet	1	2022-04-30 18:15:00.105644	2022-04-30 18:15:00.105644
2	5	6	200	TopUp wallet	1	2022-04-30 18:15:01.259313	2022-04-30 18:15:01.259313
3	5	6	200	TopUp wallet	1	2022-04-30 18:15:01.929313	2022-04-30 18:15:01.929313
4	4	5	200	TopUp wallet	1	2022-04-30 18:39:22.620743	2022-04-30 18:39:22.620743
5	4	5	200	TopUp wallet	1	2022-04-30 18:39:24.848206	2022-04-30 18:39:24.848206
6	4	5	200	TopUp wallet	1	2022-04-30 18:39:25.265926	2022-04-30 18:39:25.265926
7	4	5	200	TopUp wallet	1	2022-04-30 18:39:26.701996	2022-04-30 18:39:26.701996
8	4	5	200	TopUp wallet	1	2022-04-30 18:39:27.34686	2022-04-30 18:39:27.34686
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."user" (id, phone, pin_code_hash, is_active, create_date, last_update) FROM stdin;
6	078880000	\N	f	2022-04-30 06:31:12.877945	2022-04-30 06:31:12.877945
2	018880000	\N	t	2022-04-30 06:31:12.877945	2022-04-30 06:31:12.877945
3	028880000	\N	t	2022-04-30 06:31:12.877945	2022-04-30 06:31:12.877945
4	058880000	\N	t	2022-04-30 06:31:12.877945	2022-04-30 06:31:12.877945
5	068880000	\N	t	2022-04-30 06:31:12.877945	2022-04-30 06:31:12.877945
1	008880000	\N	t	2022-04-30 06:31:12.877945	2022-04-30 06:31:12.877945
7	000000000	\N	t	2022-04-30 07:27:25.788147	2022-04-30 07:27:25.788147
\.


--
-- Name: account_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.account_id_seq', 7, true);


--
-- Name: account_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.account_type_id_seq', 2, true);


--
-- Name: address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.address_id_seq', 5, true);


--
-- Name: city_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.city_id_seq', 3, true);


--
-- Name: client_docs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.client_docs_id_seq', 5, true);


--
-- Name: client_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.client_id_seq', 13, true);


--
-- Name: district_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.district_id_seq', 6, true);


--
-- Name: operation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.operation_id_seq', 2, true);


--
-- Name: record_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.record_id_seq', 16, true);


--
-- Name: sex_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sex_id_seq', 2, true);


--
-- Name: trans_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.trans_status_id_seq', 2, true);


--
-- Name: transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transaction_id_seq', 8, true);


--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_id_seq', 7, true);


--
-- Name: account account_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_pk PRIMARY KEY (id);


--
-- Name: account_type account_type_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_type
    ADD CONSTRAINT account_type_pk PRIMARY KEY (id);


--
-- Name: address address_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT address_pk PRIMARY KEY (id);


--
-- Name: region city_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.region
    ADD CONSTRAINT city_pk PRIMARY KEY (id);


--
-- Name: client_doc client_docs_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_doc
    ADD CONSTRAINT client_docs_pk PRIMARY KEY (id);


--
-- Name: client client_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_pk PRIMARY KEY (id);


--
-- Name: district district_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.district
    ADD CONSTRAINT district_pk PRIMARY KEY (id);


--
-- Name: operation operation_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operation
    ADD CONSTRAINT operation_pk PRIMARY KEY (id);


--
-- Name: record record_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.record
    ADD CONSTRAINT record_pk PRIMARY KEY (id);


--
-- Name: sex sex_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sex
    ADD CONSTRAINT sex_pk PRIMARY KEY (id);


--
-- Name: trans_status trans_status_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trans_status
    ADD CONSTRAINT trans_status_pk PRIMARY KEY (id);


--
-- Name: transaction transaction_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_pk PRIMARY KEY (id);


--
-- Name: user user_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pk PRIMARY KEY (id);


--
-- Name: account_account_num_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX account_account_num_uindex ON public.account USING btree (account_num);


--
-- Name: account_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX account_id_uindex ON public.account USING btree (id);


--
-- Name: account_type_code_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX account_type_code_uindex ON public.account_type USING btree (code);


--
-- Name: account_type_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX account_type_id_uindex ON public.account_type USING btree (id);


--
-- Name: address_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX address_id_uindex ON public.address USING btree (id);


--
-- Name: city_code_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX city_code_uindex ON public.region USING btree (code);


--
-- Name: city_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX city_id_uindex ON public.region USING btree (id);


--
-- Name: client_docs_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX client_docs_id_uindex ON public.client_doc USING btree (id);


--
-- Name: client_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX client_id_uindex ON public.client USING btree (id);


--
-- Name: client_itn_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX client_itn_uindex ON public.client USING btree (itn);


--
-- Name: district_code_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX district_code_uindex ON public.district USING btree (code);


--
-- Name: district_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX district_id_uindex ON public.district USING btree (id);


--
-- Name: operation_code_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX operation_code_uindex ON public.operation USING btree (code);


--
-- Name: operation_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX operation_id_uindex ON public.operation USING btree (id);


--
-- Name: record_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX record_id_uindex ON public.record USING btree (id);


--
-- Name: sex_code_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX sex_code_uindex ON public.sex USING btree (code);


--
-- Name: sex_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX sex_id_uindex ON public.sex USING btree (id);


--
-- Name: trans_status_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX trans_status_id_uindex ON public.trans_status USING btree (id);


--
-- Name: transaction_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX transaction_id_uindex ON public.transaction USING btree (id);


--
-- Name: user_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX user_id_uindex ON public."user" USING btree (id);


--
-- Name: user_phone_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX user_phone_uindex ON public."user" USING btree (phone);


--
-- Name: account account_account_type_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_account_type_id_fk FOREIGN KEY (account_type_id) REFERENCES public.account_type(id);


--
-- Name: account account_client_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_client_id_fk FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: address address_city_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT address_city_id_fk FOREIGN KEY (region_id) REFERENCES public.region(id);


--
-- Name: address address_district_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT address_district_id_fk FOREIGN KEY (district_id) REFERENCES public.district(id);


--
-- Name: client client_address_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_address_id_fk FOREIGN KEY (address_id) REFERENCES public.address(id);


--
-- Name: client client_client_doc_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_client_doc_id_fk FOREIGN KEY (client_doc_id) REFERENCES public.client_doc(id);


--
-- Name: client client_sex_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_sex_id_fk FOREIGN KEY (sex_id) REFERENCES public.sex(id);


--
-- Name: client client_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id);


--
-- Name: record record_account_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.record
    ADD CONSTRAINT record_account_id_fk FOREIGN KEY (account_id) REFERENCES public.account(id);


--
-- Name: record record_operation_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.record
    ADD CONSTRAINT record_operation_id_fk FOREIGN KEY (operation_id) REFERENCES public.operation(id);


--
-- Name: record record_transaction_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.record
    ADD CONSTRAINT record_transaction_id_fk FOREIGN KEY (trans_id) REFERENCES public.transaction(id);


--
-- Name: transaction transaction_account_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_account_id_fk FOREIGN KEY (account_from) REFERENCES public.account(id);


--
-- Name: transaction transaction_trans_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_trans_status_id_fk FOREIGN KEY (status_id) REFERENCES public.trans_status(id);


--
-- PostgreSQL database dump complete
--

