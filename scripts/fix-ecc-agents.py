#!/usr/bin/env python3
"""
OpenCode ECC Agent設定修正スクリプト
tools配列形式をオブジェクト形式に変換し、無効なcolorフィールドを削除
"""

import re
import sys
from pathlib import Path

def fix_tools_field(content):
    """tools配列をオブジェクト形式に変換"""
    pattern = r'tools:\s*\[(.*?)\]'
    
    def convert_tools(match):
        tools_str = match.group(1)
        tools = [t.strip().strip('"').strip("'") for t in tools_str.split(',')]
        
        result = 'tools:\n'
        for tool in tools:
            if tool:
                # MCPツールはそのまま、それ以外は小文字に
                key = tool if tool.startswith('mcp__') else tool.lower()
                result += f'  {key}: true\n'
        return result.rstrip()
    
    return re.sub(pattern, convert_tools, content, flags=re.DOTALL)

def fix_color_field(content):
    """無効なcolorフィールドを削除"""
    return re.sub(r'^color:.*$', '', content, flags=re.MULTILINE)

def fix_agent_file(md_file):
    """個別のagentファイルを修正"""
    try:
        content = md_file.read_text()
        original = content
        
        # tools修正
        content = fix_tools_field(content)
        # color削除
        content = fix_color_field(content)
        
        if content != original:
            md_file.write_text(content)
            return True
    except Exception as e:
        print(f'❌ Error fixing {md_file.name}: {e}', file=sys.stderr)
    return False

def main(target_dir='/home/vscode/.opencode/agents'):
    """メイン処理"""
    target_path = Path(target_dir)
    
    if not target_path.exists():
        print(f'❌ Directory not found: {target_dir}', file=sys.stderr)
        return 1
    
    fixed = 0
    total = 0
    
    for md_file in target_path.glob('*.md'):
        total += 1
        if fix_agent_file(md_file):
            print(f'✅ Fixed: {md_file.name}')
            fixed += 1
    
    print(f'\n📊 Results: {fixed}/{total} files fixed')
    return 0

if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else '/home/vscode/.opencode/agents'
    sys.exit(main(target))
