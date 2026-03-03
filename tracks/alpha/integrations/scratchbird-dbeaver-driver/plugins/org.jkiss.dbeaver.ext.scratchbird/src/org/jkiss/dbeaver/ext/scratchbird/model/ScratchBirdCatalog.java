/*
 * DBeaver - Universal Database Manager
 * Copyright (C) 2010-2026 DBeaver Corp and others
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.jkiss.dbeaver.ext.scratchbird.model;

import org.jkiss.code.NotNull;
import org.jkiss.code.Nullable;
import org.jkiss.dbeaver.DBException;
import org.jkiss.dbeaver.ext.generic.model.GenericCatalog;
import org.jkiss.dbeaver.ext.generic.model.GenericDataSource;
import org.jkiss.dbeaver.ext.generic.model.GenericSchema;
import org.jkiss.dbeaver.ext.generic.model.GenericTable;
import org.jkiss.dbeaver.model.meta.Association;
import org.jkiss.dbeaver.model.runtime.DBRProgressMonitor;
import org.jkiss.dbeaver.model.struct.DBSObject;
import org.jkiss.utils.CommonUtils;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class ScratchBirdCatalog extends GenericCatalog {

    private List<ScratchBirdSchemaNode> schemaTree;

    public ScratchBirdCatalog(@NotNull GenericDataSource dataSource, @NotNull String catalogName) {
        super(dataSource, catalogName);
    }

    @Association
    public synchronized Collection<ScratchBirdSchemaNode> getSchemaTree(@NotNull DBRProgressMonitor monitor) throws DBException {
        if (schemaTree == null && !monitor.isForceCacheUsage()) {
            buildSchemaTree(monitor);
        }
        return schemaTree == null ? Collections.emptyList() : schemaTree;
    }

    private void buildSchemaTree(@NotNull DBRProgressMonitor monitor) throws DBException {
        Collection<GenericSchema> schemas = getSchemas(monitor);
        if (CommonUtils.isEmpty(schemas)) {
            schemaTree = Collections.emptyList();
            return;
        }

        List<String> schemaPaths = new ArrayList<>();
        Map<String, GenericSchema> schemasByPath = new LinkedHashMap<>();

        for (GenericSchema schema : schemas) {
            String fullPath = schema.getName();
            if (CommonUtils.isEmpty(fullPath)) {
                continue;
            }
            schemaPaths.add(fullPath);
            schemasByPath.put(fullPath, schema);
        }

        List<ScratchBirdSchemaTreeBuilder.Node> tree = ScratchBirdSchemaTreeBuilder.build(schemaPaths);
        List<ScratchBirdSchemaNode> roots = new ArrayList<>();
        for (ScratchBirdSchemaTreeBuilder.Node root : tree) {
            roots.add(inflateTree(root, null, schemasByPath));
        }
        schemaTree = roots;
    }

    @NotNull
    private ScratchBirdSchemaNode inflateTree(
        @NotNull ScratchBirdSchemaTreeBuilder.Node source,
        @Nullable ScratchBirdSchemaNode parent,
        @NotNull Map<String, GenericSchema> schemasByPath
    ) {
        ScratchBirdSchemaNode node = new ScratchBirdSchemaNode(getDataSource(), this, parent, source.getName(), source.getFullPath());
        GenericSchema backing = schemasByPath.get(source.getFullPath());
        if (backing != null || source.isTerminal()) {
            node.setBackingSchema(backing == null ? new GenericSchema(getDataSource(), this, source.getFullPath()) : backing);
        }
        for (ScratchBirdSchemaTreeBuilder.Node child : source.getChildren()) {
            node.addChild(inflateTree(child, node, schemasByPath));
        }
        return node;
    }

    @Nullable
    @Override
    public Collection<? extends DBSObject> getChildren(@NotNull DBRProgressMonitor monitor) throws DBException {
        Collection<ScratchBirdSchemaNode> tree = getSchemaTree(monitor);
        if (!tree.isEmpty()) {
            return tree;
        }
        return super.getChildren(monitor);
    }

    @Override
    public DBSObject getChild(@NotNull DBRProgressMonitor monitor, @NotNull String childName) throws DBException {
        for (ScratchBirdSchemaNode node : getSchemaTree(monitor)) {
            if (childName.equals(node.getName())) {
                return node;
            }
        }
        return super.getChild(monitor, childName);
    }

    @NotNull
    @Override
    public Class<? extends DBSObject> getPrimaryChildType(@Nullable DBRProgressMonitor monitor) throws DBException {
        if (monitor != null && !getSchemaTree(monitor).isEmpty()) {
            return ScratchBirdSchemaNode.class;
        }
        return GenericTable.class;
    }

    @Override
    public DBSObject refreshObject(@NotNull DBRProgressMonitor monitor) throws DBException {
        schemaTree = null;
        return super.refreshObject(monitor);
    }
}
