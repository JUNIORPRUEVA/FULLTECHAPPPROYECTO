⚠️  WARNING: DO NOT EDIT FILES IN THIS FOLDER AFTER THEY'VE BEEN APPLIED

Once a migration file has been applied to ANY database (dev, staging, prod), it becomes IMMUTABLE.

WHY?
- Editing causes checksum mismatches
- Creates schema drift between environments  
- Breaks the ability to recreate databases from scratch
- Violates the migration history contract

WHAT TO DO INSTEAD?
1. Create a NEW migration file with today's date
2. Put your schema changes in the new file
3. Test locally, then commit

QUICK COMMANDS:
- Create new migration: npm run migrate:new "your description"
- View applied migrations: SELECT * FROM _sql_migrations ORDER BY applied_at;
- Read full docs: See SQL_MIGRATIONS_BEST_PRACTICES.md

FILES IN THIS FOLDER ARE READ-ONLY AFTER FIRST APPLICATION ✋
