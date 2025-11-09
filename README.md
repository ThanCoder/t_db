# TDB

TDB<T> is a base abstract class for a generic binary database.
It is designed to provide type-safe, object-oriented (OOP) database operations for any user-defined type `T`.

Key properties:

- \_index: Map<int, int> → Stores record IDs mapped to file offsets.
- \_lastId: Counter for auto-incrementing IDs.
- \_file: RandomAccessFile for reading/writing the database file.
- \_metaStore: Stores metadata in a separate binary .lock file.

Main responsibilities:

- Supports CRUD operations (insert, get, update, delete) for generic type `T`.
- Reads and writes data to a binary file using streaming for efficiency.
- Supports soft delete, file compaction (garbage collection), and index management.
- Allows changing database file paths (changePath) and loading/saving metadata.

## Myanmar

TDB<T> သည် Generic Binary Database အတွက် အခြေခံ abstract class ဖြစ်သည်။
ဤ class သည် object-oriented (OOP) နည်းဖြင့် type-safe database operations များကို လုပ်နိုင်ရန် အတွက် design လုပ်ထားသည်။

အဓိက အင်္ဂါရပ်များ:

- \_index: Map<int, int> → Record ID နှင့် file offset ကို သိမ်းဆည်းထားသည်။
- \_lastId: Auto-increment ID အတွက် counter။
- \_file: DB file ကို RandomAccessFile ဖြင့် ဖတ်/ရေးနိုင်သည်။
- \_metaStore: Meta data (.lock) file ကို သိမ်းဆည်းရန် အသုံးပြုသည်။

အဓိက responsibility များ:

- Generic type `T` အတွက် CRUD operations (insert, get, update, delete) ထောက်ပံ့သည်။
- Binary file ကို stream နည်းဖြင့် read/write လုပ်သည်။
- Soft delete / compact (file rebuild) နှင့် index management ကို ထောက်ပံ့သည်။
- Database path ပြောင်းလဲခြင်း (changePath) နှင့် meta file load/save ကို စီမံနိုင်သည်။
