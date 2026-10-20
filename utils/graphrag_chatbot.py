"""
GraphRAG Chatbot using Neo4j vector search and OpenAI.
Requires: neo4j, openai
"""

from neo4j import GraphDatabase
from openai import OpenAI


class Neo4jGraphRAG:
    """GraphRAG using Neo4j vector search + OpenAI embeddings and chat."""

    def __init__(self, neo4j_uri, neo4j_user, neo4j_password, api_key, base_url):
        self.driver = GraphDatabase.driver(neo4j_uri, auth=(neo4j_user, neo4j_password))
        self.client = OpenAI(api_key=api_key, base_url=base_url)
        self.model = "gpt-4o-mini"
        self.embedding_model = "text-embedding-3-small"
        self._setup_vector_index()

    def _setup_vector_index(self):
        """Create a Neo4j vector index on Product.embedding if it doesn't exist."""
        with self.driver.session() as session:
            session.run("""
                CREATE VECTOR INDEX product_vector_index IF NOT EXISTS
                FOR (p:Product) ON (p.embedding)
                OPTIONS {indexConfig: {
                    `vector.dimensions`: 1536,
                    `vector.similarity_function`: 'cosine'
                }}
            """)

    def embed_products(self):
        """Generate and store embeddings for all Product nodes."""
        with self.driver.session() as session:
            products = session.run("""
                MATCH (p:Product)
                RETURN p.product_name AS name, p.base_price AS price,
                       p.description AS description, elementId(p) AS id
            """).data()

        for record in products:
            text = f"{record['name']}. Price: ${record['price']}. {record['description'] or ''}"
            embedding = self.client.embeddings.create(
                model=self.embedding_model,
                input=text
            ).data[0].embedding
            with self.driver.session() as session:
                session.run(
                    "MATCH (p:Product) WHERE elementId(p) = $id SET p.embedding = $embedding",
                    id=record['id'], embedding=embedding
                )

        print(" Product embeddings created")

    def chat(self, user_query, customer_id=1):
        """Answer a question using vector search over products and customer context."""
        # Get customer context — WORKS_IN is optional; OPTIONAL MATCH handles its absence gracefully
        with self.driver.session() as session:
            result = session.run("""
                MATCH (c:Customer {customer_id: $customer_id})
                OPTIONAL MATCH (c)-[:WORKS_IN]->(i:Industry)
                RETURN c.first_name + ' ' + c.last_name AS name, i.name AS industry
            """, customer_id=customer_id).single()
        customer_name = result['name'] if result else 'Unknown'
        industry = result['industry'] if result and result['industry'] else None

        # Embed the query and retrieve relevant products via vector search
        query_embedding = self.client.embeddings.create(
            model=self.embedding_model,
            input=user_query
        ).data[0].embedding

        with self.driver.session() as session:
            hits = session.run("""
                CALL db.index.vector.queryNodes('product_vector_index', 5, $embedding)
                YIELD node, score
                RETURN node.product_name AS name, node.base_price AS price, score
            """, embedding=query_embedding).data()

        context = "\n".join(
            f"{r['name']} (${r['price']}, similarity: {r['score']:.2f})" for r in hits
        ) if hits else "No matching products found."

        system_msg = "You are a product assistant for ACME 3D Printing."
        if industry:
            system_msg += f" The customer works in the {industry} industry."

        user_msg = (
            f"Customer: {customer_name}\n\n"
            f"Relevant products from the catalog:\n{context}\n\n"
            f"Question: {user_query}"
        )

        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_msg},
                {"role": "user", "content": user_msg}
            ]
        )
        return response.choices[0].message.content

    def close(self):
        """Close the Neo4j connection."""
        self.driver.close()