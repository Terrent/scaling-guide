# data/resources/world/mail_data.gd
# Defines the content of a single piece of mail a player can receive.
class_name MailData
extends Resource

# The unique, non-human-readable identifier for this piece of mail.
@export var mail_id: StringName = &""

# The name of the sender as it appears in the mailbox UI.
@export var sender: String = ""

# The body text of the letter.
@export_multiline var content: String = ""

# A dictionary of any items included with the mail.
# Key: ItemData resource, Value: quantity (int)
@export var attached_items: Dictionary = {}
