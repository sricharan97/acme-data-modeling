# ACME Data Modeling

**Charan Konduri** — a standalone data modeling portfolio project exploring how an e-commerce company evolves its data foundations across relational, document, and graph stores.

ACME Corporation is a fictional wholesaler that sells large and small gear online. This repo designs and demonstrates the models that support that lifecycle.

---

## Project story

As ACME grows, the data platform shifts with the business:

| Part | Store | Role |
|------|--------|------|
| **1** | PostgreSQL | OLTP schema for the legacy web store (3NF) |
| **2** | MongoDB | Flexible catalog for the **ACME 3D Printing** subsidiary |
| **3** | Neo4j | Product recommendation graph (+ optional GraphRAG chatbot) |

---

## Tech stack

- **Python** + Jupyter notebook
- **PostgreSQL** (SQLAlchemy / ipython-sql)
- **MongoDB** (PyMongo)
- **Neo4j** (official Python driver + Cypher)
- **Docker Compose** for local Postgres, MongoDB, and Neo4j
- **Optional:** OpenAI-compatible API for GraphRAG (`utils/graphrag_chatbot.py`)

---

## Architecture (three parts)

### Part 1 — PostgreSQL (OLTP)

Normalized schema for customers, contact channels, products, purchases, and ratings.

**Design highlight — purchases unpivot:** the source `purchases.csv` stores flat `large_gear_*` / `small_gear_*` columns. At load time those columns are transformed into **3NF line items** keyed by `(purchase_id, product_id)`, with catalog products `104` (Large Gear) and `105` (Small Gear) injected so foreign keys hold.

DDL also lives in [`sql/01_oltp_schema.sql`](sql/01_oltp_schema.sql) for readers who prefer plain SQL.

### Part 2 — MongoDB (document model)

Database: `acme_3d_printing`. Collections: `customers`, `products`, `purchases`.

- **Embed** on customers: `latest_purchases` (orders page) and `industry_recommendations` (In Your Industry page)
- **Reference** on historical `purchases`: `customer_id` / `product_id` (plus flexible `custom_specifications`)
- **Flexible product `attributes`** so aerospace vs medical items need not share the same fields

### Part 3 — Neo4j (recommendations)

- **Nodes:** `Customer`, `Product`, `Industry`
- **Relationships:** `PURCHASED`, `ALSO_BOUGHT`, plus `WORKS_IN` and `SERVES`
- **Queries:** precomputed also-bought path, dynamic co-purchase traversal, industry popularity, product similarity

**Optional GraphRAG:** embed products into a Neo4j vector index, retrieve by similarity, and answer with customer/industry context. Helper: [`utils/graphrag_chatbot.py`](utils/graphrag_chatbot.py). API key from `VOCAREUM_API_KEY` (or compatible OpenAI key via `.env`) — never hardcoded.

---

## Skills demonstrated

- **Relational:** 3NF DDL with PKs/FKs, typed columns, CHECKs/UNIQUEs, CSV load with purchase unpivot
- **Document:** embedding vs referencing trade-offs, polymorphic product attributes, filtered PyMongo queries
- **Graph:** recommendation traversals (`PURCHASED` / `ALSO_BOUGHT`), industry and similarity queries
- **Optional:** GraphRAG + vector search over product nodes

---

## Repository layout

```
acme-data-modeling/
├── README.md
├── LICENSE
├── .env.example
├── .gitignore
├── requirements.txt
├── docker-compose.yml
├── data/                          # sample CSVs
├── notebooks/
│   └── ACME_Data_Modeling_Project.ipynb
├── sql/
│   └── 01_oltp_schema.sql
└── utils/
    └── graphrag_chatbot.py        # optional GraphRAG helper
```

---

## How to run locally

### 1. Start databases

```bash
docker compose up -d
```

Defaults:

| Service | Connection |
|---------|------------|
| Postgres | `postgresql://postgres:postgres@127.0.0.1:5432/postgres` |
| MongoDB | `mongodb://root:root@127.0.0.1:27017/?authSource=admin` → DB `acme_3d_printing` |
| Neo4j | Bolt `bolt://127.0.0.1:7687` — user `neo4j` / password `neo4jpass` |

### 2. Python environment

```bash
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Jupyter

```bash
jupyter notebook notebooks/ACME_Data_Modeling_Project.ipynb
```

Run top to bottom. CSV paths resolve whether the kernel cwd is the repo root or `notebooks/`.

### 4. Optional GraphRAG

```bash
cp .env.example .env
# set VOCAREUM_API_KEY=... in .env
```

Base URL used by the helper: `https://openai.vocareum.com/v1`. Parts 1–3 do **not** require this key.

---

## License

MIT — see [`LICENSE`](LICENSE).
