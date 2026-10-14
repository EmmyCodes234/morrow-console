const fs = require('fs');
const path = require('path');

const REPLACEMENTS = [
  // Primary Navigation & Tabs
  ['CONVERSATIONS:"Conversations"', 'CONVERSATIONS:"Cases"'],
  ['ALL_CONVERSATIONS:"All Conversations"', 'ALL_CONVERSATIONS:"All Cases"'],
  ['CONTACTS:"Contacts"', 'CONTACTS:"Customers"'],
  ['ALL_CONTACTS:"All Contacts"', 'ALL_CONTACTS:"All Customers"'],
  ['INBOX:"My Inbox"', 'INBOX:"Assigned to Me"'],
  ['UNATTENDED_CONVERSATIONS:"Unattended"', 'UNATTENDED_CONVERSATIONS:"Needs Attention"'],
  ['UNATTENDED_HEADING:"Unattended"', 'UNATTENDED_HEADING:"Needs Attention"'],
  ['REPORTS:"Reports"', 'REPORTS:"Insights"'],
  ['CANNED_RESPONSES:"Canned Responses"', 'CANNED_RESPONSES:"Saved Replies"'],
  ['TAB_HEADING:"Conversations"', 'TAB_HEADING:"Cases"'],
  ['HEADER:{TITLE:"Contacts"', 'HEADER:{TITLE:"Customers"'],
  ['"ALL_CONVERSATIONS":"All Conversations"', '"ALL_CONVERSATIONS":"All Cases"'],
  ['"CONVERSATIONS":"Conversations"', '"CONVERSATIONS":"Cases"'],
  ['"CONTACTS":"Contacts"', '"CONTACTS":"Customers"'],
  ['TITLE:"Contacts"', 'TITLE:"Customers"'],
  ['SEARCH_TITLE:"Search contacts"', 'SEARCH_TITLE:"Search customers"'],
  ['ACTIVE_TITLE:"Active contacts"', 'ACTIVE_TITLE:"Active customers"'],
  ['HEADER:"Conversations"', 'HEADER:"Cases"'],
  ['METRICS:{CONVERSATIONS:{NAME:"Conversations"', 'METRICS:{CONVERSATIONS:{NAME:"Cases"'],
  ['DOWNLOAD_CONVERSATION_REPORTS:"Download conversation reports"', 'DOWNLOAD_CONVERSATION_REPORTS:"Download case reports"'],
  ['EMPTY_CONVERSATIONS:"No conversations yet."', 'EMPTY_CONVERSATIONS:"No cases yet."'],
  ['NO_MATCHING_CONVERSATIONS:"No conversations match these filters."', 'NO_MATCHING_CONVERSATIONS:"No cases match these filters."'],
  ['NO_RECORDS_FOUND:"There are no previous conversations associated to this contact."', 'NO_RECORDS_FOUND:"There are no past cases for this customer."'],
  ['TITLE:"Previous Conversations"', 'TITLE:"Past Cases"'],
  ['VIEW_ALL:"View all conversations"', 'VIEW_ALL:"View all cases"'],
  ['EMPTY_STATE_DEFAULT:"Search by conversation id, email, phone number, messages for better search results. "', 'EMPTY_STATE_DEFAULT:"Search by case ID, email, phone number, or messages."'],
  ['PRIVATE:"Private note"', 'PRIVATE:"Internal note"'],
  ['SEARCH_MESSAGES:"Search for messages in conversations"', 'SEARCH_MESSAGES:"Search for messages in cases"'],
  ['NO_INBOX_AGENT:"Uh Oh! Looks like you are not part of any inbox. Please contact your administrator"', 'NO_INBOX_AGENT:"You are not assigned to any channel. Please contact your administrator."'],

  // Empty states & Messages
  ['"Uh oh! Looks like there are no messages from customers in your inbox."', '"No customer cases in your queue."'],
  ['"There are no active conversations in this group."', '"No active cases in this queue."'],
  ['"Hola! Looks like you haven\'t added any inboxes yet."', '"No channels connected yet."'],
  ['"to send a message to your page!"', '"to send a test case."'],
  ['"Please select a conversation from left pane"', '"Select a case from the list"'],
  ['"All conversations loaded 🎉"', '"All cases loaded"'],
  ['"All conversations loaded"', '"All cases loaded"'],
  ['"Loading inboxes"', '"Loading channels"'],
  ['"Loading Conversations"', '"Loading Cases"'],
  ['"Resolve conversation"', '"Close Case"'],
  ['"Resolve"', '"Close Case"'],
  ['CAPTAIN:"Captain"', 'CAPTAIN:"Morrow AI"'],
  ['CAPTAIN_AI:"Captain"', 'CAPTAIN_AI:"Morrow AI"'],
  ['"Captain"', '"Morrow AI"'],
  ['"Shift + enter for new line. Start with \'/\' to select a Canned Response."', '"Shift + enter for new line. Type \'/\' for saved replies."'],
  ['select a Canned Response', 'select a Saved Reply'],
  ['a Canned Response', 'a Saved Reply'],
  ['Canned Response', 'Saved Reply'],
  ['Canned Responses', 'Saved Replies'],
  ['canned response', 'saved reply'],
  ['canned responses', 'saved replies'],

  // Branding & Woot references
  ['Login to Chatwoot', 'Sign in to Morrow'],
  ['Could not connect to Woot server', 'Could not connect to Morrow server'],
  ['Powered by Chatwoot', 'Powered by Morrow'],
  ['Chatwoot', 'Morrow'],
  ['#2781F6', '#059669'],
  ['#2781f6', '#059669']
];

function patchFile(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  let changed = false;

  for (const [target, replacement] of REPLACEMENTS) {
    if (content.includes(target)) {
      content = content.replaceAll(target, replacement);
      changed = true;
    }
  }

  if (changed) {
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`[PATCHED] ${filePath}`);
  }
}

function walkAndPatch(dir) {
  if (!fs.existsSync(dir)) return;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walkAndPatch(fullPath);
    } else if (entry.isFile() && (entry.name.endsWith('.js') || entry.name.endsWith('.css'))) {
      patchFile(fullPath);
    }
  }
}

// Support running directly on specified dir or default dirs
const targetDirs = process.argv.slice(2);
if (targetDirs.length > 0) {
  targetDirs.forEach(dir => {
    if (fs.existsSync(dir)) {
      if (fs.statSync(dir).isDirectory()) {
        walkAndPatch(dir);
      } else {
        patchFile(dir);
      }
    }
  });
} else {
  ['/app/public/vite', '/app/public/packs', './public/vite', './public/packs'].forEach(dir => {
    walkAndPatch(dir);
  });
}
console.log('Patching process finished.');
