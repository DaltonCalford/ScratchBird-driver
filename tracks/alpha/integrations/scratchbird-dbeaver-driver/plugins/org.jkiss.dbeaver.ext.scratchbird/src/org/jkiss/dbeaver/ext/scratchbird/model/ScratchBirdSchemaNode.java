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
import org.jkiss.dbeaver.ext.generic.model.GenericObjectContainer;
import org.jkiss.dbeaver.ext.generic.model.GenericSchema;
import org.jkiss.dbeaver.ext.generic.model.GenericStructContainer;
import org.jkiss.dbeaver.ext.generic.model.GenericTable;
import org.jkiss.dbeaver.model.DBPSystemObject;
import org.jkiss.dbeaver.model.meta.Association;
import org.jkiss.dbeaver.model.runtime.DBRProgressMonitor;
import org.jkiss.dbeaver.model.struct.DBSEntity;
import org.jkiss.dbeaver.model.struct.DBSObject;
import org.jkiss.dbeaver.model.struct.rdb.DBSSchema;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class ScratchBirdSchemaNode extends GenericObjectContainer implements DBSSchema, DBPSystemObject {

    private final ScratchBirdCatalog ownerCatalog;
    @Nullable
    private final ScratchBirdSchemaNode parentSchema;
    @NotNull
    private final String name;
    @NotNull
    private final String fullPath;
    @NotNull
    private GenericSchema querySchema;
    @NotNull
    private final Map<String, ScratchBirdSchemaNode> childSchemas = new LinkedHashMap<>();

    public ScratchBirdSchemaNode(
        @NotNull GenericDataSource dataSource,
        @NotNull ScratchBirdCatalog ownerCatalog,
        @Nullable ScratchBirdSchemaNode parentSchema,
        @NotNull String name,
        @NotNull String fullPath
    ) {
        super(dataSource);
        this.ownerCatalog = ownerCatalog;
        this.parentSchema = parentSchema;
        this.name = name;
        this.fullPath = fullPath;
        this.querySchema = new GenericSchema(dataSource, ownerCatalog, fullPath);
    }

    void addChild(@NotNull ScratchBirdSchemaNode child) {
        childSchemas.putIfAbsent(child.getName(), child);
    }

    void setBackingSchema(@NotNull GenericSchema backingSchema) {
        this.querySchema = backingSchema;
    }

    @Association
    public Collection<ScratchBirdSchemaNode> getChildSchemas(@NotNull DBRProgressMonitor monitor) {
        return childSchemas.values();
    }

    @NotNull
    public String getFullPath() {
        return fullPath;
    }

    @Nullable
    @Override
    public GenericCatalog getCatalog() {
        // ScratchBird SQL object names are schema-qualified, not catalog-qualified.
        return null;
    }

    @Override
    public GenericSchema getSchema() {
        return querySchema;
    }

    @NotNull
    @Override
    public GenericStructContainer getObject() {
        return this;
    }

    @NotNull
    @Override
    public String getName() {
        return name;
    }

    @Nullable
    @Override
    public String getDescription() {
        return null;
    }

    @Override
    public DBSObject getParentObject() {
        return parentSchema == null ? ownerCatalog : parentSchema;
    }

    @NotNull
    @Override
    public Class<? extends DBSEntity> getPrimaryChildType(@Nullable DBRProgressMonitor monitor) throws DBException {
        return GenericTable.class;
    }

    @Override
    public Collection<? extends DBSObject> getChildren(@NotNull DBRProgressMonitor monitor) throws DBException {
        List<DBSObject> children = new ArrayList<>(childSchemas.values());
        children.addAll(getTables(monitor));
        return children;
    }

    @Override
    public DBSObject getChild(@NotNull DBRProgressMonitor monitor, @NotNull String childName) throws DBException {
        ScratchBirdSchemaNode schemaNode = childSchemas.get(childName);
        if (schemaNode != null) {
            return schemaNode;
        }
        return super.getChild(monitor, childName);
    }

    @Override
    public boolean isSystem() {
        String normalizedPath = fullPath.toLowerCase(Locale.ENGLISH);
        return normalizedPath.equals("sys") || normalizedPath.startsWith("sys.");
    }
}
