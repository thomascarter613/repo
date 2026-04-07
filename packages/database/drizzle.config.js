export default {
    schema: "./src/schema.ts",
    out: "./drizzle",
    dialect: "postgresql",
    dbCredentials: {
        url: process.env.DATABASE_URL ?? "postgres://app:app@localhost:5432/app"
    }
};
//# sourceMappingURL=drizzle.config.js.map