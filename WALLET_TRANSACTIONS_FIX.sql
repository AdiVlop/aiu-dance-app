-- WALLET_TRANSACTIONS CONSTRAINT FIX
-- Acest script corectează constraint-ul pentru tipurile de tranzacții în wallet_transactions

-- 1. Verifică constraint-ul actual
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'wallet_transactions'::regclass 
  AND contype = 'c';

-- 2. Elimină constraint-ul existent dacă există
DO $$
BEGIN
    -- Elimină toate constraint-urile de tip check pentru coloana type
    IF EXISTS (
        SELECT 1 
        FROM pg_constraint 
        WHERE conrelid = 'wallet_transactions'::regclass 
          AND contype = 'c' 
          AND conname LIKE '%type%'
    ) THEN
        ALTER TABLE wallet_transactions DROP CONSTRAINT IF EXISTS wallet_transactions_type_check;
        RAISE NOTICE 'Constraint eliminat cu succes';
    END IF;
END $$;

-- 3. Adaugă constraint-ul corect
ALTER TABLE wallet_transactions 
ADD CONSTRAINT wallet_transactions_type_check 
CHECK (type IN ('credit', 'debit'));

-- 4. Verifică că constraint-ul a fost adăugat corect
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'wallet_transactions'::regclass 
  AND contype = 'c'
  AND conname = 'wallet_transactions_type_check';

-- 5. Testează inserarea cu tipurile corecte
DO $$
BEGIN
    -- Test inserare cu 'credit'
    INSERT INTO wallet_transactions (user_id, type, amount, description)
    VALUES ('9195288e-d88b-4178-b970-b13a7ed445cf', 'credit', 100.00, 'Test credit');
    
    -- Test inserare cu 'debit'  
    INSERT INTO wallet_transactions (user_id, type, amount, description)
    VALUES ('9195288e-d88b-4178-b970-b13a7ed445cf', 'debit', -50.00, 'Test debit');
    
    -- Șterge testele
    DELETE FROM wallet_transactions WHERE description IN ('Test credit', 'Test debit');
    
    RAISE NOTICE 'Testele au trecut cu succes!';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Eroare la test: %', SQLERRM;
END $$;

-- 6. Afișează toate tranzacțiile existente pentru verificare
SELECT id, user_id, type, amount, description, created_at 
FROM wallet_transactions 
ORDER BY created_at DESC 
LIMIT 10;

-- 7. Actualizează toate tranzacțiile existente cu tipuri incorecte
UPDATE wallet_transactions 
SET type = 'debit' 
WHERE type NOT IN ('credit', 'debit') 
  AND amount < 0;

UPDATE wallet_transactions 
SET type = 'credit' 
WHERE type NOT IN ('credit', 'debit') 
  AND amount >= 0;

-- Mesaj de succes
SELECT '✅ Constraint wallet_transactions actualizat cu succes!' as status;
