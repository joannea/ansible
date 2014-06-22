#!powershell
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON

$params = Parse-Args $args;

$path = Get-Attr $params "path" (Get-Attr $params "dest" (Get-Attr $params "name" $false));
If (-not $path)
{
    Fail-Json "missing required argument: path";
}

$state = Get-Attr $params "state" "file";

# recurse, group, mode, owner, force, src are not currently supported for Windows.

$result = New-Object psobject @{
    path = $path
    state = $state
};

Switch ($state)
{
    "file"
    {
        If (Test-Path -PathType Leaf $path)
        {
            Set-Attr $result "size" (Get-Item $path).length;
            Set-Attr $result "changed" $false;
        }
        ElseIf (Test-Path -PathType Container $path)
        {
            Set-Attr $result "state" "directory";
            Fail-Json $result ("file (" + $path + ") is directory, cannot continue");
        }
        Else
        {
            Set-Attr $result "state" "absent";
            Fail-Json $result ("file (" + $path + ") is absent, cannot continue");
        }
    }
    "directory"
    {
        If (Test-Path -PathType Leaf $path)
        {
            Set-Attr $result "state" "file";
            Set-Attr $result "size" (Get-Item $path).length;
            Set-Attr $result "changed" $false;
        }
        ElseIf (Test-Path -PathType Container $path)
        {
            Set-Attr $result "changed" $false;
        }
        Else
        {
            New-Item -ItemType Directory -Path $path;
            Set-Attr $result "changed" $true;
        }
    }
    "absent"
    {
        If (Test-Path $path)
        {
            Remove-Item $path -Force -Recurse;
            Set-Attr $result "changed" $true;
        }
        Else
        {
            Set-Attr $result "changed" $false;
        }
    }
    "touch"
    {
        $result = New-Object psobject @{
            dest = $path
        };
        If (Test-Path -PathType Leaf $path)
        {
            (Get-ChildItem $path).LastWriteTime = Get-Date;
            Set-Attr $result "state" "file";
            Set-Attr $result "changed" $true;
            Set-Attr $result "size" (Get-Item $path).length;
        }
        ElseIf (Test-Path -PathType Container $path)
        {
            (Get-ChildItem $path).LastWriteTime = Get-Date;
            Set-Attr $result "state" "directory";
            Set-Attr $result "changed" $true;
        }
        Else
        {
            New-Item -ItemType File -Path $path;
            Set-Attr $result "state" "file";
            Set-Attr $result "changed" $true;
            Set-Attr $result "size" (Get-Item $path).length;
        }
    }
    default
    {
        Fail-Json ("value of state must be one of: file,directory,touch,absent, got: " + $state);
    }
}

Exit-Json $result;
