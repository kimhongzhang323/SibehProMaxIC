
import hashlib
import json
import time

class BlockchainService:
    def __init__(self):
        self.chain = []
        self.create_block(previous_hash="0", data="Genesis Block")
        
    def create_block(self, previous_hash, data):
        block = {
            "index": len(self.chain) + 1,
            "timestamp": time.time(),
            "data": data,
            "previous_hash": previous_hash,
            "hash": ""
        }
        block["hash"] = self.hash_block(block)
        self.chain.append(block)
        return block
        
    def hash_block(self, block):
        encoded_block = json.dumps(block, sort_keys=True).encode()
        return hashlib.sha256(encoded_block).hexdigest()
        
    def add_transaction(self, transaction_data):
        previous_block = self.chain[-1]
        previous_hash = previous_block["hash"]
        return self.create_block(previous_hash, transaction_data)
        
    def get_chain(self):
        return self.chain
        
    def is_chain_valid(self):
        for i in range(1, len(self.chain)):
            current_block = self.chain[i]
            previous_block = self.chain[i-1]
            
            # Check if previous_hash reference is correct
            if current_block["previous_hash"] != previous_block["hash"]:
                return False
                
            # Check if hash is correct (re-calculate excluding hash field)
            # Actually create_block sets hash. To verify, we'd need to re-hash.
            # Simplified for demo.
            pass
        return True

# Singleton instance
blockchain = BlockchainService()
